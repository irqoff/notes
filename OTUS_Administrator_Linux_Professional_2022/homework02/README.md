# homework02

## Basic Part

Create a RAID:
```
# mdadm --create /dev/md/data --level raid10 --name data --raid-disks 4 /dev/sd{b,c,d,e}

# lsblk 
NAME    MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda       8:0    0 19.5G  0 disk   
|-sda1    8:1    0    2G  0 part   [SWAP]
`-sda2    8:2    0 17.6G  0 part   /
sdb       8:16   0    1G  0 disk   
`-md0     9:0    0    2G  0 raid10 
sdc       8:32   0    1G  0 disk   
`-md0     9:0    0    2G  0 raid10 
sdd       8:48   0    1G  0 disk   
`-md0     9:0    0    2G  0 raid10 
sde       8:64   0    1G  0 disk   
`-md0     9:0    0    2G  0 raid10 
```

Test the RAID:
```
# mdadm --manage --set-faulty /dev/md/data /dev/sdb
mdadm: set /dev/sdb faulty in /dev/md0
# mdadm --manage --set-faulty /dev/md/data /dev/sdd
mdadm: set /dev/sdd faulty in /dev/md0

# mdadm --detail /dev/md/data
/dev/md0:
           Version : 1.2
     Creation Time : Fri Aug  5 19:04:45 2022
        Raid Level : raid10
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Fri Aug  5 19:06:17 2022
             State : clean, degraded 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 2
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : server:data  (local to host server)
              UUID : 32a844a8:18b1cb18:42f18e65:935b09dd
            Events : 21

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       32        1      active sync set-B   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync set-B   /dev/sde

       0       8       16        -      faulty   /dev/sdb
       2       8       48        -      faulty   /dev/sdd
```

Repair the RAID:
```
# mdadm /dev/md/data -r /dev/sdb
mdadm: hot removed /dev/sdb from /dev/md0
# mdadm /dev/md/data -a /dev/sdb
mdadm: added /dev/sdb
# mdadm /dev/md/data -r /dev/sdd
mdadm: hot removed /dev/sdd from /dev/md0
# mdadm /dev/md/data -a /dev/sdd
mdadm: added /dev/sdd

# cat /proc/mdstat 
Personalities : [raid10] 
md0 : active raid10 sdd[5] sdb[4] sde[3] sdc[1]
      2093056 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>
```

Create a configuration:
```
# mdadm --examine --scan --config=mdadm.conf > /etc/mdadm.conf

# cat /etc/mdadm.conf 
ARRAY /dev/md/data  metadata=1.2 UUID=32a844a8:18b1cb18:42f18e65:935b09dd name=server:data
```

## Part with *

Just run `vargrant up` with [Vagrantfile](./Vagrantfile)
```
[vagrant@server ~]$ df -h /srv/data
Filesystem      Size  Used Avail Use% Mounted on
/dev/md127      2.0G  6.0M  1.9G   1% /srv/data
```
