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
mv Documents documents
mv Downloads downloads
mv Pictures pictures
mkdir projects
mkdir repos
mkdir projects/arch_linux
mkdir projects/bash
mkdir projects/CC++
mkdir projects/ghidra
mkdir projects/hackthebox
mkdir projects/python
mkdir projects/rust
mkdir projects/tauri
mkdir projects/tryhackme
mkdir projects/virtualbox
mkdir projects/x86_64

echo "Installing packages from installed_packages.txt..."
packages=($(<installed_packages.txt))
sudo pacman -S --needed --noconfirm "${packages[@]}"

echo "Building packages from git repos ..."

echo "Moving configuration files into place ..."
mv ./configs/alacritty ~/.config/
mv ./configs/dconf ~/.config/
mv ./configs/i3 ~/.config/
mv ./configs/nitrogen ~/.config/
mv ./configs/picom ~/.config/
mv ./configs/polybar ~/.config/
mv ./configs/ranger ~/.config/
mv ./configs/rofi ~/.config/
mv ./configs/zathura ~/.config/

