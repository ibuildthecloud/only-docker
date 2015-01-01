#!/bin/bash
set -e

cat > sha1sums << EOF
85d4160537546a23a7e42bc26dd7ee62a0ede4c8  iptables-1.4.21.tar.bz2
1c9b87dbaa11a0778a0a656b4ba03a148e17a775  docker-1.4.1.tgz
53e6b5e4d29d5df3832cc656e37fd994a4f86d3b  linux-3.18.1.tar.xz
EOF

# Manually download big files
if ! sha1sum -c sha1sums >/dev/null 2>&1; then
    wget -O linux-3.18.1.tar.xz https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.18.1.tar.xz
    wget -O iptables-1.4.21.tar.bz2 http://www.netfilter.org/projects/iptables/files/iptables-1.4.21.tar.bz2
    wget -O docker-1.4.1.tgz https://get.docker.com/builds/Linux/x86_64/docker-1.4.1.tgz
fi

docker build -t od .
docker rm -f od-build >/dev/null 2>&1 || true
docker run -d --name od-build od /bin/true

rm -rf dist
mkdir -p dist/kvm
docker cp od-build:/usr/src/only-docker/ dist
cp kvm/run.sh dist
gzip -dc kvm/empty-hd.img.gz > dist/kvm/empty-hd.img
