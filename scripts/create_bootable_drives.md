# Preparing bootable media

## BIOS

* Disable secure boot and TPM (trusted platform module)
* Enable legacy USB support
* Disable all RAID configurations and use AHCI mode

## Windows

The windows key is stored in the BIOS acpi tables. You can retrieve it with :
`hexdump -C /sys/firmware/acpi/tables/MSDM`

Download the iso image from MS. Then prepare a USB stick with a single bootable FAT32 partition
`parted /dev/sdX mktable gpt`
`parted /dev/sdX mkpart fat32 0% 100%`
`parted /dev/sdX set 1 boot on`
`mkfs.fat -F32 -n WIN10USB /dev/sdX1`

Mount the iso image and copy all files into the USB stick
`losetup --find windows10.iso`
`mount /dev/loopX /mnt/iso`
`mount /dev/sdX1 /mnt/usb`
`cp -r /mnt/iso/* /mnt/usb`
`umount /mnt/iso`
`umount /mnt/usb`
`losetup -D`

## Linux

Download net image and check image hash with gpg/sha256sum

### Easiest method 

This is a read only filesystem and default xorg config is **not good for RAT5 mouse**
`dd if=<iso> of=<root_device> bs=4M`

### livecd-iso-to-disk method

* [live usb][1] (you need a live image, netinstaller does not work) 
* `livecd-iso-to-disk --efi --format --unencrypted-home --home-size-mb 2048 --overlay-size-mb 1024 --label <LESS_than_11_chars> <live_iso> /dev/<usb>`
* You can boot into the live system and patch xorg.conf to get the mouse working
* **Problem** : installer in the live image has less options (at least for fedora)

### GRUB2 method (tested on ubuntu)

Not the best method because the live image will have a readonly filesystem (like the dd method)
Start by preparing the USB stick with an EFI boot and OS partitions
`parted /dev/sdX mktable gpt`
`parted /dev/sdX mkpart fat32 1024KiB 128MiB`
`parted /dev/sdX mkpart ext4 128MiB 100%`
`parted /dev/sdX set 1 boot on`
`parted /dev/sdX set 1 bios_grub on`
`mkfs.fat -F32 -n EFIBOOTUSB /dev/sdX1`
`mkfs.ext4 -L LINUXOS /dev/sdX2`

Mount the iso image and copy all files into the USB stick
`losetup --find linux_os.iso`
`mount /dev/loopX /mnt/iso`
`mount /dev/sdX2 /mnt/usb`
`rm -rf /mnt/usb/* /mnt/usb/.* # the system may have created a lost+found dir`
`cp -r /mnt/iso/* /mnt/iso/.* /mnt/usb`
`umount /mnt/iso`
`umount /mnt/usb`
`losetup -D`

Look into the copied files for directories `EFI` and `boot`. Check that they contain the grub2 modules, efi executable and `grub.cfg`.
Then just copy them to the EFI partition, better to copy also in EFI/BOOT depending on BIOS.
`mount /dev/sdX1 /mnt/efi`
`mount /dev/sdX2 /mnt/usb`
`cp -r /mnt/usb/boot /mnt/usb/EFI /mnt/efi`
`cp -r /mnt/efi/EFI/linuxos /mnt/efi/EFI/BOOT`
`cp /mnt/efi/EFI/BOOT/grubx64.efi /mnt/efi/EFI/BOOT/BOOTx64.EFI`
`umount /mnt/usb`
`umount /mnt/efi`

Otherwise you can create a grub2 installation manually. 
**Prerequisite** you need packages `grub2` and `grub2-efi-modules` installed in the host were you build the USB.
`grub2-install --boot-directory=/mnt/efi/boot --target=x86_64-efi --efi-directory=/mnt/efi`

Then you need to create `grub.cfg` with the manual entry for the USB stick. Edit `/etc/grub.d/*_custom` to add the menuentry.
**Determine the following criteria**
* Distribution custom kernel boot parameters
* Location of compressed kernel image
* Location of initial ramdisk (and load the correct grub module for decompression)

    menuentry 'Linux OS version' --unrestricted {
      insmod gzio
      insmod lzopio
      insmod part_gpt
      insmod ext2
      search --no-floppy --fs-uuid --set=root LINUXOS_UUID
      linux ???/vmlinuz.efi ????
      initrd ???/initrd.lz
    }

Generate the configuration into the EFI partition. The edit to remove all entries but the one you added manually.
`grub2-mkconfig -o /mnt/efi/EFI/BOOT/grub.cfg`

[1]: https://fedoraproject.org/wiki/How_to_create_and_use_Live_USB#Command_line_method:_Using_the_livecd-iso-to-disk_tool_.28Fedora_only.2C_non-graphical.2C_both_non-destructive_and_destructive_methods_available.29

