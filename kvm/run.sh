#!/bin/bash

cd $(dirname $0)

kvm -hda kvm/empty-hd.img -kernel only-docker/vmlinuz -initrd only-docker/initrd -m 1024
