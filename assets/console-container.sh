#!/bin/sh
set -e

CONSOLE_IMAGE=debian
if [ "$IN_MEMORY" = "true" ]; then
    CONSOLE_IMAGE=busybox
fi

while sleep 1; do
    if docker ps >/dev/null 2>&1; then
        break
    fi
done

echo Setting up network
if ! docker inspect dhcp >/dev/null 2>&1; then
    docker import - dhcp < /.dhcp.tar
fi
docker run --rm -it --net host --cap-add NET_ADMIN dhcp udhcpc -i eth0

echo Setting up console image
if ! docker inspect console-image >/dev/null 2>&1; then
    docker pull ${CONSOLE_IMAGE}
    docker tag ${CONSOLE_IMAGE} console-image:latest
fi

while true; do
    if docker inspect console >/dev/null 2>&1; then
        docker start -ai console
    else
        docker run \
            --rm \
            -v /proc:/host/proc:ro \
            -v /lib/modules:/lib/modules:ro \
            -v /bin/docker:/usr/bin/docker:ro \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            --privileged \
            --net host \
            -it \
            console-image:latest
    fi
    sleep 1
done
