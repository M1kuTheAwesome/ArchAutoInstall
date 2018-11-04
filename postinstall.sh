#!/bin/bash

PACKAGES='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/packages.list'
AURLIST='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/aur.list'
HOOK='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/mirrorupgrade.hook'
SERVICE='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/reflector.service'
TIMER='https://raw.githubusercontent.com/M1kuTheAwesome/ArchAutoInstall/master/reflector.timer'

sudo dhcpcd
# Ask if laptop, install power management tools if yes

while true
do
    read -p'Is this a laptop? ' LAPTOP
    case $LAPTOP in
        [Yy]* ) sudo pacman -S --noconfirm xfce4-power-manager; break;;
        [Nn]* ) break;;
        * ) echo "Yes or no only, please.";;
    esac
done

echo 'Select correct graphics driver.'
select VGA in 'xf86-video-intel' 'xf86-video-amdgpu' 'xf86-video-ati' \
'xf86-video-nouveau' 'nvidia' 'nvidia-390xx' 'nvidia-340xx' 'none'
do
	case $VGA in
		'none')
		echo "$VGA selected"
		VGA=''
		;;
		*)
		echo "$VGA selected"
		;;
	esac
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

sudo curl -o /etc/pacman.d/hooks/mirrorupgrade.hook $HOOK
sudo curl -o /etc/systemd/system/reflector.service $SERVICE
sudo curl -o /etc/systemd/system/reflector.timer $TIMER
sudo systemctl enable reflector.timer


# install yay
curl -sO 'https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz'
tar -xvf yay-bin.tar.gz && cd yay-bin
makepkg --noconfirm -si

# install AUR packages
curl -sO $AURLIST
yay -S --noconfirm $(cat aur.list)

# enable stuff for some installed packages
sudo systemctl enable pcscd
sudo usermod -aG kalu mihkel

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

