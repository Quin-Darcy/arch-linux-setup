#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

echo "Starting post-installation setup..."

function sync_time {
    echo "Synchronizing hardware clock..."
    sudo timedatectl set-ntp true
    sudo hwclock --systohc
}

function update_mirrorlist {
    echo "Updating mirrorlist..."
    sudo reflector -c US -a 6 --save /etc/pacman.d/mirrorlist
}

function refresh_packages {
    echo "Refreshing package database..."
    sudo pacman -Syy

    echo "Updating system..."
    sudo pacman -Syu --noconfirm

    echo "Enabling reflector timer service ..."
    sudo systemctl enable --now reflector.timer
}

function setup_directories {
    echo "Cleaning up and reorganizing home directory..."
    for dir in Music Templates Videos Desktop; do
        [[ -d "$HOME/$dir" ]] && rm -r "$HOME/$dir"
    done

    mv "$HOME/Documents" "$HOME/documents"
    mv "$HOME/Downloads" "$HOME/downloads"
    mv "$HOME/Pictures" "$HOME/pictures"

    cp ./resources/background1.jpg "$HOME/pictures/backgrounds"

    mkdir -p "$HOME/projects" {"$HOME/projects"/{arch_linux,bash,C,ghidra,hackthebox,python,rust/{binaries,libraries,tests},tauri,tryhackme,virtualbox,x86_64}}
}

function install_packages {
    echo "Installing packages from installed_packages.txt..."
    packages=($(<installed_packages.txt))
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

function enable_lightdm {
    echo "Enabling lightdm ..."
    sudo systemctl enable lightdm
}

function get_repos {
    echo "Building packages from git repos ..."

    mkdir "$HOME/repos"
    cd "$HOME/repos"
    git clone https://aur.archlinux.org/yay-git.git
    cd yay-git
    makepkg -sri
    cd ..

    yay -S brave-bin

    mkdir -p "$HOME/repos/rust"
    cd "$HOME/repos/rust"
    curl https://sh.rustup.rs -sSf | sh
    source "$HOME/.cargo/env"
    cd "$HOME"

    cd "$HOME/repos"
    git clone https://aur.archlinux.org/marktext.git
    cd marktext
    makepkg -si
    cd "$HOME"
}

function configure_system {
    echo "Moving configuration files into place..."
    declare -A configs=( [".bashrc"]="$HOME" [".vimrc"]="$HOME" ["alacritty"]="~/.config" ["dconf"]="~/.config" ["i3"]="~/.config" ["marktext"]="~/.config" ["nitrogen"]="~/.config" ["picom"]="~/.config" ["polybar"]="~/.config" ["ranger"]="~/.config" ["rofi"]="~/.config" ["zathura"]="~/.config")
    for config in "${!configs[@]}"; do
        cp -r "./configs/$config" "${configs[$config]}"
    done
}

sync_time
update_mirrorlist
refresh_packages
setup_directories
install_packages
configure_system

echo "Post-installation setup completed successfully."

