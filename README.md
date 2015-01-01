# Only Docker

Running Docker as PID 1.  This is an experiment to see if I can build a system that boots with only the Linux kernel and the Docker binary and nothing else.  Currently I have a proof of concept running that seems to indicate this is feasible.  You may be of the opinion that this is awesome or the worst idea ever.  I think it's interesting, so let's just go with that.

## Running

**Currently I only have this running under KVM**.  VirtualBox support will come soon enough (well, unless I get distracted by other shiny objects and not do it...)
```
wget ...
tar xvzf docker-only.tar.gz
./run.sh
```

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

When the system boots and you get a console your in a container.  If you run `ps` you just see the container's processes.  It's actually hard to get into the root of the machine to see what's there.  If you want proof, change the kvm script and add `-append console` to it.  That will launch a shell in the root.

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
