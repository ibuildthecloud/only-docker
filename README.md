# Only Docker

Running Docker as PID 1.  This is an experiment to see if I can build a system that boots with only the Linux kernel and the Docker binary and nothing else.  Currently I have a proof of concept running that seems to indicate this is feasible.  You may be of the opinion that this is awesome or the worst idea ever.  I think it's interesting, so let's just go with that.

## Running

Currently I only have this running under KVM and VirtualBox.

### KVM

Download `only-docker.tar.gz` from [releases](https://github.com/ibuildthecloud/only-docker/releases)
```
tar xvzf docker-only.tar.gz
./dist/kvm/run.sh
```

### VirtualBox

Create a VM that boots from `dist/only-docker.iso`

## Idea

1. Create ramdisk that has Docker binary copied in as /init
1. Register a new reexec hook so that Docker will run differently as init
1. On start Docker will
  1. Create any devices needed in dev
  1. Mount /proc, /sys, cgroups
  1. Mount LABEL=DOCKER to /var/lib/docker if it exists
  1. Start regular dockerd process
1. Network bootstrap
  1. Do 'docker run --net host dhcp` to do DHCP
1. Run "dom0" container
  1. Start a priviledge container that can do further stuff like running udev, ssh, etc

The "dom0" container follows a model very similar to Xen's dom0.  It is a special container that has extra privileges and runs basically like it is the host OS but it happens to be in a container.  Pretty cool to think about the idea of upgrading/restarting this container without a system reboot.

## Status

I currently have something running in KVM.  I'm using some shell scripts because it was faster then trying to write all this in native go.  I've kept that in mind though and purposely kept the scripts to very basic tasks I know can be easily done in go.

There are two main scripts: `init` and `console-container.sh`.  `init` is intended to be the code in Docker that runs before the daemon is fully initialized.  `console-container.sh` is the code that runs after the Docker daemon is started that does the DHCP and launching the "dom0" container.

## Issues

1. Docker still needs iptables binary, which in turn needs modprobe.
1. Since I need to bootstrap DHCP I bundle a Docker image in the initrd that I can import on start.  This means I can't have *only* the Docker binary.
1. How do you shutdown?  I guess it's a crash only design :)

## But I don't see Docker as PID 1?

When the system boots and you get a console your in a container.  If you run `ps` you just see the container's processes.  By default a console is spawned on VT2 (Alt-F2) that is in the host OS.  If you switch to that console and run ps you will see that Docker is PID 1.

## Customizing

The console container is launched using the image labeled `console-image:latest`.  If one does not exist `busybox` will be used if `/dev/sda` was not mounted, or `debian` if `/dev/sda` was mounted.  To use a different image just pull your custom image and then label it as `console-image:latest` and then exit out of your console.  A new container will be launched.

## Adding storage

By default this runs using only ram which makes start up slow and limits the amount of images you can pull.  If you want to add storage then add a formated disk as `/dev/sda` (not `/dev/sda1`, don't partition it, just format the raw disk).  The KVM script automatically attaches a formatted disk.  To format a disk in VirtualBox then just do the following after boot.

```
docker pull debian:latest
docker tag debian:latest console-image:latest
exit
mke2fs -j /dev/sda
```
Now reboot the virtual machine.

# License
Copyright (c) 2014 [Rancher Labs, Inc.](http://rancher.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
