#!/bin/bash

echo "KEYMAP=$1" > /etc/vconsole.conf

# setting timezone and time
ln -sf /usr/share/zoneinfo/$2 /etc/localtime
hwclock --systohc
sed -i '/en_US.UTF_8/s/^#//g' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

#Configure hostname
echo $3 > /etc/hostname
(
echo "127.0.0.1	localhost"
echo "::1		localhost"
echo "127.0.1.1	$3.localdomain	$3"
)>/etc/hosts

# Install correct microcode updates
if grep 'GenuineIntel' /proc/cpuinfo
then
	pacman -S --noconfirm intel-ucode
elif grep 'AuthenticAMD' /proc/cpuinfo
then
	pacman -S --noconfirm amd-ucode
else
	echo 'What manner of CPU is this?'
	exit 1
fi

# Install and configure grub
pacman -S --noconfirm grub os-prober
if [ -d "/sys/firmware/efi" ]
then
	pacman -S --noconfirm efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
	grub-install --target=i386-pc /dev/sda
fi
grub-mkconfig -o /boot/grub/grub.cfg

echo "root:$4" | chpasswd

# optimize building packages
sed -i -e 's/x86-64/native/' /etc/makepkg.conf
sed -i '/MAKEFLAGS=/s/^#//g' /etc/makepkg.conf
sed -i -e "s/j2/j$(nproc)/" /etc/makepkg.conf
sed -i -e 's/gzip/pigz/' /etc/makepkg.conf
sed -i -e 's/(xz -c -z -)/(xz -c -z - --threads=0)/' /etc/makepkg.conf

# add user and make it sudo
useradd -m -g users -G wheel -s /bin/bash $5
echo "$5:$6" | chpasswd
echo "$5 ALL=(ALL:ALL) ALL" | EDITOR="tee -a" visudo

# no beep and more color!
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
sed -i "s/^#Color/Color/g" /etc/pacman.conf