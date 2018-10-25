#!/bin/bash

CHROOT='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/chroot.sh'

# Ask for variables
read -p 'User: ' USER
read -p 'Password for user: ' USERPW
read -p 'Root password: ' ROOTPW
KEYMAP=et
read -p 'hostname: ' HOSTNAME
TIMEZONE=Europe/Tallinn
read -p 'Swap size(in MiB): ' SWAP

timedatectl set-ntp true

#Calculate block size based on sector size 
((BLOCKSIZE=1048576/$(cat /sys/block/sda/queue/hw_sector_size)))

#Count no of existing partitions
PARTAMOUNT=$(grep -c 'sda[0-9]' /proc/partitions)

#if there are none, make a boot partition and addd to counting
if [ $PARTAMOUNT == 0 ]
then
	parted --script /dev/sda \
		unit s \
		mkpart primary fat32 $BLOCKSIZE 1128447 \
		set 1 boot on \
		quit
	mkfs.fat -F32 /dev/sda1
	((PARTAMOUNT=$PARTAMOUNT+1))
fi

#determine where swap partition should start
#
((STSECTOR=$(cat /sys/block/sda/sda$PARTAMOUNT/start)+$(cat /sys/block/sda/sda$PARTAMOUNT/size)))

#and same for the next after swap
((SWAPEND=($STSECTOR+$SWAP*$BLOCKSIZE)-1))
((MAINSTART=$SWAPEND+1))
((DISKSIZE=$(cat /sys/block/sda/size)-$BLOCKSIZE))

parted --script /dev/sda \
	unit s \
	mkpart primary linux-swap $STSECTOR $SWAPEND \
	mkpart primary ext4 $MAINSTART $DISKSIZE \
	quit

#make fs and swap & mount
((PARTAMOUNT=$PARTAMOUNT+1))
mkswap /dev/sda$PARTAMOUNT && swapon /dev/sda$PARTAMOUNT
((PARTAMOUNT=$PARTAMOUNT+1))
mkfs.ext4 /dev/sda$PARTAMOUNT && mount /dev/sda$PARTAMOUNT /mnt
mkdir /mnt/boot && mount /dev/sda1 /mnt/boot

pacman -Syu --noconfirm pacman-contrib
# Creating mirrorlist and ranking mirrors
curl -s 'https://www.archlinux.org/mirrorlist/?country=FI&country=LV&country=SE&protocol=https&use_mirror_status=on' \
| sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist

# Installing base and base-devel packages
pacstrap /mnt base base-devel

#generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

#engage chroot phase
curl -sO $CHROOT
cp chroot.sh /mnt/chroot.sh

cat << EOF | arch-chroot /mnt
	bash chroot.sh $KEYMAP $TIMEZONE $HOSTNAME $ROOTPW $USER $USERPW
EOF

rm /mnt/chroot.sh
curl -O 'https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/postinstall.sh'
mv postinstall.sh /mnt/home/$USER/postinstall.sh
# all done ,unmount and reboot
umount -R /mnt/boot
umount -R /mnt
reboot
