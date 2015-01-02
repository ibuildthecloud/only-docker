#!/bin/bash

cd $(dirname $0)

kvm -hda empty-hd.img -cdrom ../only-docker.iso -m 1024
