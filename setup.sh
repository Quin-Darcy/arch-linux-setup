#!/bin/bash

echo "Syncronizing hardware clock ..."
sudo timedatectl set-ntp true
sudo hwclock --systohc

echo "Updating mirrorlist ..."
sudo reflector -c US -a 6 --save /etc/pacman.d/mirrorlist

echo "Refreshing package database ..."
sudo pacman -Syy

echo "Updating system ..."
sudo pachman -Syu --noconfirm

echo "Enabling reflector timer service ..."
sudo systemctl enable --now reflector.timer

echo "Cleaning up home directory ..."
rm -r ~/Music
rm -r ~/Templates
rm -r ~/Videos
rm -r ~/Desktop
mv ~/Documents ~/documents
mv ~/Downloads ~/downloads
mv ~/Pictures ~/pictures
mkdir ~/pictures/backgrounds
cp ./resources/background1.jpg ~/pictures/backgrounds 
mkdir ~/projects
mkdir ~/repos
mkdir ~/projects/arch_linux
mkdir ~/projects/bash
mkdir ~/projects/CC++
mkdir ~/projects/ghidra
mkdir ~/projects/hackthebox
mkdir ~/projects/python
mkdir ~/projects/rust
mkdir ~/projects/rust/binaries
mkdir ~/projects/rust/libraries
mkdir ~/projects/tauri
mkdir ~/projects/tryhackme
mkdir ~/projects/virtualbox
mkdir ~/projects/x86_64

echo "Installing packages from installed_packages.txt..."
packages=($(<installed_packages.txt))
sudo pacman -S --needed --noconfirm "${packages[@]}"

echo "Enabling lightdm ..."
sudo systemctl enable lightdm

echo "Building packages from git repos ..."
cd ~/repos
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -sri
cd ..
yay -S brave-bin
git clone https://github.com/pwndbg/pwndbg
cd pwndbg
./setup.sh
cd ..
curl https://sh.rustup.rs -sSf | sh
source "$HOME/.cargo/env"
git clone https://aur.archlinux.org/python310.git
cd python310
makepkg -si
cd ..
git clone https://aur.archlinux.org/marktext.git
cd marktext
makepkg -si
cd ..

echo "Moving configuration files into place ..."
cp ./configs/.bashrc ~/.bashrc
cp ./configs/.vimrc ~/.vimrc
cp -r ./configs/alacritty ~/.config/
cp -r ./configs/dconf ~/.config/
cp -r ./configs/i3 ~/.config/
cp -r ./configs/marktext ~/.config/
cp -r ./configs/nitrogen ~/.config/
cp -r ./configs/picom ~/.config/
cp -r ./configs/polybar ~/.config/
cp -r ./configs/ranger ~/.config/
cp -r ./configs/rofi ~/.config/
cp -r ./configs/zathura ~/.config/

