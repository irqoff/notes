# homework01

## Vagrant Cloud

Install vagrant and packer
```
$ vagrant version
Installed Version: 2.2.19
Latest Version: 2.2.19
 
You're running an up-to-date version of Vagrant!

$ packer version
Packer v1.8.2
```
Fix outdated parts in [Vagrantfile](./packer/Vagrantfile) and [stage-2-clean.sh](./packer/scripts/stage-2-clean.sh).

Run vagrant and check kernel version:
```
$ vagrant  ssh
[vagrant@kernel-update ~]$ uname -r
5.18.15-1.el7.elrepo.x86_64
```
Publish the box:
```
vagrant cloud publish --release --no-private irqoff/centos-7-9 1.0 virtualbox centos-7.9.2009-kernel-5-x86_64-Minimal.box


Complete! Published irqoff/centos-7-9
Box:              irqoff/centos-7-9
Description:      
Private:          no
Created:          2022-08-01T06:08:50.834Z
Updated:          2022-08-01T06:08:50.834Z
Current Version:  N/A
Versions:         1.0
Downloads:        0
```

## Build Kernel
In [build directory](./build), build vagrant box by packer and up it. Then install dependencies:
```
yum groupinstall "Development Tools"
yum -y install net-tools xmlto asciidoc hmaccalc python-devel newt-devel pesign elfutils-libelf-devel elfutils-devel zlib-devel binutils-devel audit-libs-devel java-devel numactl-devel pciutils-devel python-docutils perl-ExtUtils-Embed.noarch ncurses-devel kernel-devel
rpm -i http://vault.centos.org/7.9.2009/updates/Source/SPackages/kernel-3.10.0-1160.66.1.el7.src.rpm
```
Then change Kernel identity in spec file, enable dmesg restriction for non-root and build RPM packages:
```
cp /usr/src/kernels/3.10.0-1160.71.1.el7.x86_64/.config ../SOURCES/kernel-3.10.0-x86_64.config
rpmbuild -bb --target=`uname -m` kernel.spec
```
Install them, reboot and check:
```
rpm -i ./rpmbuild/RPMS/x86_64/kernel-3.10.0-1160.71.1.el7.irqoff.x86_64.rpm
$ uname -a
Linux localhost.localdomain 3.10.0-1160.71.1.el7.irqoff.x86_64 #1 SMP Mon Aug 1 12:44:05 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
$ dmesg 
dmesg: read kernel buffer failed: Operation not permitted
```

## Build Module

Install other dependencies:
```
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y dkms
rpm -i ./rpmbuild/RPMS/x86_64/kernel-devel-3.10.0-1160.71.1.el7.irqoff.x86_64.rpm
rpm -i ./rpmbuild/RPMS/x86_64/kernel-header-3.10.0-1160.71.1.el7.irqoff.x86_64.rpm
```
Mount VBoxGuestAdditions and install the module:
```
sudo mkdir /media/VBoxGuestAdditions
sudo mount -o loop,ro VBoxGuestAdditions.iso /media/VBoxGuestAdditions
sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
```
Clean ./rpmbuild and other places, then public the box:
```
Complete! Published irqoff/centos-7-9-custom
Box:              irqoff/centos-7-9-custom
Description:      
Private:          no
Created:          2022-08-02T00:53:38.246Z
Updated:          2022-08-02T00:53:39.905Z
Current Version:  N/A
Versions:         1.0
Downloads:        0
```
Up it and test shared folder:
```
[vagrant@localhost ~]$ cd /vagrant/
[vagrant@localhost vagrant]$ ls
centos-7.9.2009-custom-x86_64-Minimal.box  centos-7.9.2009-vanilla-x86_64-Minimal.box  centos.json  http  scripts  Vagrantfile
```
