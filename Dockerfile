FROM ubuntu:14.10
RUN apt-get update
RUN apt-get install -y \
        busybox-static \
        bc
RUN apt-get build-dep -y --no-install-recommends iptables
# This causes iptables to fail to compile... don't know why yet
RUN apt-get purge -y libnfnetlink-dev

# Build static iptables
COPY iptables-1.4.21.tar.bz2 /usr/src/
RUN cd /usr/src && \
    tar xjf iptables-1.4.21.tar.bz2 && \
    cd iptables-1.4.21 && \
    ./configure --enable-static --disable-shared && \
    make -j4 LDFLAGS="-all-static"

# Build kernel
COPY linux-3.18.1.tar.xz /usr/src/
RUN cd /usr/src && \
    tar xJf linux-3.18.1.tar.xz
COPY assets/kernel_config /usr/src/linux-3.18.1/.config
RUN cd /usr/src/linux-3.18.1 && \
    make oldconfig
RUN apt-get install -y bc
RUN cd /usr/src/linux-3.18.1 && \
    make -j4 bzImage
RUN cd /usr/src/linux-3.18.1 && \
    make -j4 modules
RUN mkdir -p /usr/src/root && \
    cd /usr/src/linux-3.18.1 && \
    make INSTALL_MOD_PATH=/usr/src/root modules_install firmware_install

# Taken from boot2docker
# Remove useless kernel modules, based on unclejack/debian2docker
RUN cd /usr/src/root/lib/modules && \
    rm -rf ./*/kernel/sound/* && \
    rm -rf ./*/kernel/drivers/gpu/* && \
    rm -rf ./*/kernel/drivers/infiniband/* && \
    rm -rf ./*/kernel/drivers/isdn/* && \
    rm -rf ./*/kernel/drivers/media/* && \
    rm -rf ./*/kernel/drivers/staging/lustre/* && \
    rm -rf ./*/kernel/drivers/staging/comedi/* && \
    rm -rf ./*/kernel/fs/ocfs2/* && \
    rm -rf ./*/kernel/net/bluetooth/* && \
    rm -rf ./*/kernel/net/mac80211/* && \
    rm -rf ./*/kernel/net/wireless/*

# Install docker
RUN apt-get install -y ca-certificates
COPY docker-1.4.1.tgz /usr/src/
RUN mkdir -p /usr/src/root/bin && \
    tar xvzf /usr/src/docker-1.4.1.tgz --strip-components=3 -C /usr/src/root/bin

# Create dhcp image
RUN /usr/src/root/bin/docker -s vfs -d --bridge none & \
    sleep 1 && \
    /usr/src/root/bin/docker pull busybox && \
    /usr/src/root/bin/docker run --name export busybox false ; \
    /usr/src/root/bin/docker export export > /usr/src/root/.dhcp.tar

# Install isolinux
RUN apt-get install -y \
    isolinux \
    xorriso

# Start assembling root
COPY assets/init /usr/src/root/
COPY assets/console-container.sh /usr/src/root/bin/
RUN cd /usr/src/root/bin && \
    cp /bin/busybox . && \
    chmod u+s busybox && \
    cp /usr/src/iptables-1.4.21/iptables/xtables-multi iptables && \
    strip --strip-all iptables && \
    for i in mount modprobe mkdir openvt sh mknod; do \
        ln -s busybox $i; \
    done && \
    cd .. && \
    mkdir -p ./etc/ssl/certs && \
    cp /etc/ssl/certs/ca-certificates.crt ./etc/ssl/certs && \
    ln -s bin sbin
RUN mkdir -p /usr/src/only-docker/boot && \
    cd /usr/src/root && \
    find | cpio -H newc -o | lzma -c > ../only-docker/boot/initrd && \
    cp /usr/src/linux-3.18.1/arch/x86_64/boot/bzImage ../only-docker/boot/vmlinuz
RUN mkdir -p /usr/src/only-docker/boot/isolinux && \
    cp /usr/lib/ISOLINUX/isolinux.bin /usr/src/only-docker/boot/isolinux && \
    cp /usr/lib/syslinux/modules/bios/ldlinux.c32 /usr/src/only-docker/boot/isolinux
COPY assets/isolinux.cfg /usr/src/only-docker/boot/isolinux/
# Copied from boot2docker, thanks.
RUN cd /usr/src/only-docker && \
    xorriso \
        -publisher "Rancher Labs, Inc." \
        -as mkisofs \
        -l -J -R -V "OnlyDocker-v0.1" \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -o /only-docker.iso $(pwd)
