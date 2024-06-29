# Arch Linux Installation

---

#### Release Info

- Current Release: 2024.06.01

- Included Kernel: 6.9.3
  
  

### Pre-Requisites

Before following the instructions below, there are several tools we will need. Make sure the following things are installed:

- transmission-gtk

- gnugpg
  
  

### Acquiring the ISO image



**Verifying Signature**

1. Download the [PGP signature](https://archlinux.org/iso/2024.06.01/archlinux-2024.06.01-x86_64.iso.sig) for the ISO image.

2. Open a terminal and navigate to the location of the PGP signature.

3. Verify the signature file

```bash
gpg --keyserver-options auto-key-retrieve --verify archlinux-2024.06.01-x86_64.iso.sig
```

4. If the signature is valid, you should see a message stating "Good signature from ..."
   
   

**Downloading the ISO**

1. Download the [torrent file](https://archlinux.org/releng/releases/2024.06.01/torrent/) associated with the newest ISO image.

2. Launch `transmission-gtk`.

3. Click *Open* and select the downloaded torrent file.

4. After the download is complete, *Right-Click > Open Folder*

5. Note the location of the ISO file.

6. Open a terminal and navigate to the location of the ISO file.

7. Compute the SHA256 hash of the ISO file with 

```bash
sha256sum archlinux-2024.06.01-x86_64.iso
```

8. Compare the output of the above command to the [official hash value](https://archlinux.org/iso/2024.06.01/sha256sums.txt).

9. If the hashes match, proceed.



### Creating Bootable USB

# 

1. Insert the USB drive you intend to boot from.

2. Run `lsblk` to list all connected disks and identify the device name of your drive.

3. Unmount the USB drive if it is mounted

```bash
sudo umount /dev/<device name>
```

4. In a terminal, navigate to the directory containing the ISO file.

5. Write the ISO to the USB drive - **Do not include partition number**.

```bash
sudo dd bs=4M if=archlinux-2024.06.01-x86_64.iso of=/dev/<device name> status=progress oflag=sync
```

6. Run `sync` to ensure all pending writes are completed.

7. Eject the USB

```bash
sudo eject /dev/<device name>
```

---

###### Connecting to WiFi

After booting up from the ISO, we will first connect to WiFi. 
1. Start `iwd` with
```bash
iwctl
```
2. List the wireless interfaces with
```bash
device list
```
3. Scan the available networks with
```bash
station [device name] scan
```
4. List the available networks found in scan
```bash
station [device name] get-networks
```
5. Connect to the desired network
```bash
station [device name] connect [network name]
```
6. Exit with
```bash
exit
```
7. Test connectivity with
```bash
ping google.com
```

--- 

###### Updating Mirror List

After confirming an internet connection, we need to syncronize the network time protocol (NTP). To do this we will run

`timedatectl set-ntp true`

Now we need to use [Reflector](https://wiki.archlinux.org/title/reflector) to update our mirror list. This package comes pre-installed in the Arch Linux ISO. We will run 

`reflector -c US -a 6 --save /etc/pacman.d/mirrorlist`

Next we will update by running 

`pacman -Syy`

---

###### Creating Disk Partitions

1. List the block devices with
```bash
lsblk
``` 
2. After identifying the target partition (usually the one with largest capacity)
```bash
gdisk /dev/[disk name]
```
3. Delete old partitions (Repeat for each partition)
```bash
d
```
4. Create new EFI partition
```bash
n
```
5. Press `Enter` twice
6. Set the size of the partition
```bash
+260M
``` 
7. Set the partition type to EFI
```bash
ef00
```
8. Create new swap partition
```bash
n
```
9. Press `Enter` twice
10. Set the size of the partition
```bash
+16G
```
11. Set the partition type to Linux swap
```bash
8200
```
12. Create root partition
```bash
n
```
13. Press `Enter` four times.
14. Write the changes
```bash
w
```
15. Confirm new partitions by listing block devices
```bash
lsblk
```
16. Format the EFI partition
```bash
mkfs.fat -F32 /dev/[first partition name]
```
17. Format the swap partition
```bash
mkswap /dev/[second partition name]
```
18. Activate the swap partition
```bash
swapon /dev/[second partition name]
```

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
