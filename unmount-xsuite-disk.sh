#!/bin/bash

umount /data/virtuals/xsuite/ROOT
umount /data/virtuals/xsuite/BOOT

cryptsetup remove /dev/mapper/xsuite2-root

sleep 2
losetup -d /dev/loop1 
losetup -d /dev/loop2
losetup -a

vmware-mount -x
vmware-mount -L
