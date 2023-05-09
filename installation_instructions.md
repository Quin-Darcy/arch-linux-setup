# Arch Linux Installation

---

### Acquiring the ISO image

The recommended way to [download](https://archlinux.org/download/) the Arch Linux ISO is to use a torrent client. In the event you do not have a torrent client already installed, run the following command

`sudo pacman -S transmission-gtk`

After the install finishes, you should be able to launch the program. Once the program is open, select *Open* at the top left-hand corner and open your downloaded torrent file. 

Once the download completes, right-click the file and select *Open Folder*. This should bring you to the location the new ISO was placed.

We now want to verify its signature. To do this, we need GnuPG installed. In the event, it is not already installed, run the following command

`sudo pacman -S gnupg`

Next we will need the [ISO PGP signature](https://archlinux.org/iso/2022.11.01/archlinux-2022.11.01-x86_64.iso.sig). We will now verify its signature with the following command from within the directory the .SIG file was downloaded

`gpg --keyserver-options auto-key-retrieve --verify archlinux-*version*-x86_64.iso.sig`

As one final check of the ISO's integrity, you can check its SHA256 hash by running 

`sha256sum archlinux-*version*-x86_64.iso`

and comparing the output of that to the listed SHA256 hash in the **checksum** section of the [Downloads](https://archlinux.org/download/#checksums) page. 

### Installation

---

###### Connecting to WiFi

After booting up from the ISO, we will first connect to WiFi. To do this, we will use [iwd](https://wiki.archlinux.org/title/Iwd). Run the following command to start *iwd*:`iwctl`. Then to list the wireless devices available, run `device list`. Next, we need to scan the networks available to us. To do this, run 

`station [device name] scan`

Next, to get the list of networks scanned run

`station [device name] get-networks`

To connect to a given network, run

`station [device name] connect [network name]`

--- 

###### Updating Mirror List

After confirming an internet connection, we need to syncronize the network time protocol (NTP). To do this we will run

`timedatectl set-ntp tue`

Now we need to use [Reflector](https://wiki.archlinux.org/title/reflector) to update our mirror list. This package comes pre-installed in the Arch Linux ISO. We will run 

`reflector -c US -a 6 --save /etc/pacman.d/mirrorlist`

Next we will update by running 

`pacman -Syy`

---

###### Creating Disk Partitions

We will run `lsblk` to list the disks. After identifying the disk to partition (generally it is the one with the most storage), we will run `gdisk /dev/[disk name]`.  Once this comes up, we will press `n` for new, then press `Enter` for the first two lines, then type `+260M` in the *Last Sector* field. 

We will change this to an [EFI type filesystem](https://en.wikipedia.org//wiki/EFI_system_partition) by typing `ef00`.  

Next we will create our [swap partition](https://opensource.com/article/18/9/swap-space-linux-systems) by typing `n` for new, then pressing `Enter` for the first two lines. Next, when setting the size of the partition, it should be twice the size of the RAM. Type `+[partition size]G`. Next, on the last line type `8200` to set the type as *SWAP*. 

Finally, to create our root partition, we type `n`  for new, then `Enter` for the next four lines. To write the changes to the disk, type `w`, then `Y` to accept the changes.

To confirm these changes, we will type `lsblk` again to look at the disks. 

Now we need to format the partitions. We will type 

`mkfs.fat -F32 /dev/[first partition name]`

Now to make the *SWAP* on the second partition, we type 

`mkswap /dev/[second partition name]`

and activate it by typing 

`swapon /dev/[second partition name]`

###### Encrypting the Root Partition

Start by typing

`cryptsetup -y -v luksFormat /dev/[third partition name]`

After confirming and setting the passphrase, we need to open the partition. We will type

`cryptsetup open /dev/[third partition name] [mapper (whatever) name]`

Now that it is open, we can format it. Type 

`mkfs.ext4 /dev/mapper/[mapper name]`

###### Mounting the Partitions

Now that the partitions are all formatted, we can mount them. To mount the root partition to the mount point `/mnt`, we will type 

`mount /dev/mapper/[mapper name] /mnt`

To mount the EFI partition into the boot directory, we first need to create the boot directory. To do this, we first need to create this directory by  typing 

`mkdir /mnt/boot`

And now we can mount the first partition by typing 

`mount /dev/[first partition name] /mnt/boot`

###### Installing the Base Packages

Run the following command to install the base packages

`pacstrap /mnt base linux linux-firmware vim intel-ucode`

###### Generate Filesystem Table

This is where the mount points are stored. To do this, we type 

`genfstab  -U /mnt >> /mnt/etc/fstab`

The `-U` flag is to use the [uuid](https://en.wikipedia.org/wiki/Universally_unique_identifier). 

To move into the filesystem, type 

`arch-chroot /mnt`

###### Setting the Time Zone, Locales, Hostname, etc.

To set out time zone information, we will type 

`timedatectl list-timezone`

After locating the time zone nearest you, we set it by typing 

`ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime`

Now we syncronize the clocks by typing

`hwclock --systohc`

To set the locales, we type

`vim /etc/locale.gen`

Remove the hashtag from the line that says `en_US.UTF8`, save and quit Vim. Then generate the locales by typing 

`locale-gen`

Now we need to create the `locale.conf` file. Do this by typing 

`vim /etc/locale.conf`

Add the following line to the file

`LANG=en_US.UTF-8`

To set the hostname of the machine, type 

`vim /etc/hostname`

and add the name of your machine to the file. 

Now we edit the hosts file by typing

`vim /etc/hosts`

Add the following lines to your file

```bash
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1     localhost
::1           localhost
127.0.1.1     [HOSTNAME].localdomain [HOSTNAME]
```

Now set the password for the root user by typing `passwd`.

###### Installing System Packages

Install the packages for the system by running 

`pacman -S grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-headers xdg-utils xdg-user-dirs alsa-utils git reflector`

###### Final steps

Since we have encrypted our root partition, we need to change the following lines in the `/etc/mkinitcpio.conf` file. Type 

`vim /etc/mkinitcpio.conf`

and modify the hooks line to say

`HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)`

Now re-create the image by typing 

`mkinitcpio -p linux`

###### Install GRUB Boot Loader

To install the boot loader, type (NOTE: if you are doing this on a VM, be sure to enable UEFI mode in the VM settings)

`grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB`

Now we generate the configuration file by running 

`grub-mkconfig -o /boot/grub/grub.cfg`

We also need to change the configuration file we just made since we are using encryption. So we need the UUID of `[third partition name]` and to provide the mapper name of that partition. 

To get the UUID we type 

`blkid`

To copy the UUID, we will redirect the output of the above command into a file and copy it from there. Type 

`blkid > uuid`

vim into the file and copy the line with the UUID of /dev/[third partition name]. 

With the UUID in the clipboard, type

`vim /etc/default/grub`

Now paste the UUID line in between the quotes of the `GRUB_CMDLINE_LINUX=` line. In total it should look like

`GRUB_CMDLINE_LINUX="cryptdevice=UUID=[uuid]:[mapper name] root=/dev/mapper/[mapper name]"`

Now regenerate the configuration file by re-reunning 

`grub-mkconfig -o /boot/grub/grub.cfg`

###### Enable Services for after Reboot

Type 

`systemctl enable Networkmanager`

###### Create User

Type 

`useradd -mG wheel [username]`

Create password for the user by running

`passwd [username]`

###### Change Editor for VISUDO

Type 

`EDITOR=vim visudo`

Once in the visudo file, find the first line that mentions `wheel` and remove the hashtag. 

###### Testing the Installation

Type `exit` to leave the `/mnt` directory. Then unmount all the partitions by typing 

`umount -a`

Then `reboot`

### First Login

Once you have rebooted and logged in run 

`git clone https://github.com/Quin-Darcy/arch-linux-setup.git`

`cd arch-linux-setup`

`./setup.sh`  

### Misc. Notes

--- 

###### Transparency in windows

Picom is auto-started in the i3 config file. That is, in `~/.config/i3/config` the line 

`exec --no-startup-ip picom -f &`

is what starts picom. 

When adjusting transparency of windows, this is done through the `~/.conf/picom/picom.conf` file. Specifically, 

```
opacity-rule = [
    "60:class_g = 'URxvt' && focused", # for focused windows
    "30:class_g = 'URxvt' && !focused"  
];
```

The values 60 and 30 can be any where from 10 to 90 and are what control the level of opacity. 

Also note that while in vitural box, the following line is needed in the `picom.conf` file

`vsync = false`

###### 

###### polybar setup

After installing polybar, the following launch script is saved as `~/.config/polybar/launch.sh` and ran from the `i3` boot strap section of `~/.config/i3/config`. 

To see everything that polybar is doing, reload it and direct output to stdout with the highest loglevel

`polybar -r --log=trace -s`
