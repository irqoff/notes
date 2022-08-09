# homework03

## LVM

There is no way to reduce XFS size online. Extend memory to 2G and boot from SystemRescue. Then recreate the root partition:
```
# mkfs.ext4 /dev/sda
# mkdir /mnt/{root,backup}
# mount /dev/sda /mnt/backup
# mount /dev/mapper/VolGroup00-LogVol00 /mnt/root
# xfsdump -f /mnt/backup/backup /mnt/root
# lvreduce /dev/VolGroup00/LogVol00 -L 8G
# mkfs.xfs -m crc=0,reflink=0 -f /dev/VolGroup00/LogVol00
# mount /dev/mapper/VolGroup00-LogVol00 /mnt/root
# xfsrestore -f /mnt/backup/backup /mnt/root
# umount /mnt/{root,backup}
# sync; reboot
```
Check after reboot:
```
$ df -h /
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00  8.0G  823M  7.2G  11% /
````

Then create a LVM mirror for home:
```
# pvcreate /dev/sd{d,e}       
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
# vgcreate var /dev/sd{d,e}
  Volume group "var" successfully created
# lvcreate -L 900M -m 1 -n var var
  Logical volume "var" created.
# mkfs.ext4 -L var /dev/var/var
```
Add in /etc/fstab:
```
LABEL="var" /var ext4 defaults,noauto 0 2
```
And copy /var:
```
# mount -a
# rsync -a /var/ /mnt
# umount /mnt
```
Reboot the server, check and remove old /var:
```
[root@lvm vagrant]#  ls /var
adm  cache  db  empty  games  gopher  kerberos  lib  local  lock  log  lost+found  mail  nis  opt  preserve  run  spool  tmp  yp
```

Repeat for home, add in /etc/fstab:
```
UUID="b5928caf-158f-4351-a511-fa019409dab7" /home xfs defaults,noquota 0 2
```

Now check snapshot. First create files:
```
$ test test{0..20}
```
Then create a snapshot, remove files and restore them:
```
# lvcreate -L 200M -s -n home_backup home/home
  Logical volume "home_backup" created.
$ rm test{0..20}
# umount /home
# lvconvert --merge /dev/home/home_backup              
# mount /home
$ ls   
test0  test1  test10  test11  test12  test13  test14  test15  test16  test17  test18  test19  test2  test20  test3  test4  test5  test6  test7  test8  test9
```

## ZFS

Create disks for pool and cache:
```
# lvcreate -n disk1 -L 1G VolGroup00
  Logical volume "disk1" created.
# lvcreate -n disk2 -L 1G VolGroup00
  Logical volume "disk2" created.
# lvcreate -n cache -L 1G VolGroup00
  Logical volume "cache" created.
```
Install ZFS:
```
yum install https://zfsonlinux.org/epel/zfs-release-2-2$(rpm --eval "%{dist}").noarch.rpm
yum install -y zfs
```

Create a pool:
```
# zpool create tank mirror /dev/VolGroup00/disk{1,2} cache /dev/VolGroup00/cache
# zfs create tank/opt                 
# zfs set mountpoint=/opt tank/opt
# df -h /opt
Filesystem      Size  Used Avail Use% Mounted on
tank/opt        832M  128K  832M   1% /opt
```
Test snapshots:
```
# echo "version 1" > /opt/version
# zfs snapshot tank/opt@version1
# zfs list -t snapshot
NAME                USED  AVAIL     REFER  MOUNTPOINT
tank/opt@version1     0B      -     24.5K  -
# echo "version 2" > /opt/version
# cat /opt/version
version 2
# zfs rollback tank/opt@version1
# cat /opt/version              
version 1
```
