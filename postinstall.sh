#!/bin/bash

PACKAGES='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/packages.list'
AURLIST='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/aur.list'
HOOK='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/mirrorupgrade.hook'
SERVICE='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/reflector.service'
TIMER='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/reflector.timer'

sudo dhcpcd

echo 'Select correct graphics driver.'
echo 'See https://wiki.archlinux.org/index.php/Hardware_video_acceleration for help'
select VGA in 'xf86-video-intel intel-media-driver' 'xf86-video-intel libva-intel-driver' \
'xf86-video-amdgpu libva-mesa-driver' 'xf86-video-ati libva-mesa-driver' \
'nvidia nvidia-utils' 'none'
do
	echo "$VGA selected"
	break
done

# installing packages from packages.list
curl -sO $PACKAGES
while IFS= read -r package
do
	sudo pacman -S --noconfirm $package
done < packages.list
rm packages.list

#installing VGA drivers
if [[ $VGA ]]
then
	sudo pacman -S --noconfirm $VGA
fi

# configure UFW
sudo systemctl enable ufw
sudo ufw default deny
sudo ufw enable

# enable lxdm and NetworkManager systemd
sudo systemctl enable lxdm
sudo systemctl enable NetworkManager

# Copy pacman hook and systemd stuff for reflector

sudo mkdir /etc/pacman.d/hooks
sudo curl -o /etc/pacman.d/hooks/mirrorupgrade.hook $HOOK
sudo curl -o /etc/systemd/system/reflector.service $SERVICE
sudo curl -o /etc/systemd/system/reflector.timer $TIMER
sudo systemctl enable reflector.timer


# install yay
curl -sO 'https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz'
tar -xvf yay-bin.tar.gz && cd yay-bin
makepkg --noconfirm -si
cd .. && rm -r yay-bin && rm yay-bin.tar.gz

# install AUR packages
curl -sO $AURLIST
yay -S --noconfirm $(cat aur.list)
rm aur.list

# enable stuff for some installed packages
sudo systemctl enable pcscd

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

