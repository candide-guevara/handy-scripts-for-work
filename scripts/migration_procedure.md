# Change home workstation

## Prerequisites

### New physical node

* Build it ! 
* Prepare SATA+POWER connectors for drives in the current installation

### Prepare installation media

* Download net image and check image hash
* Copy to usb-stick
    * simple method : `dd if=<iso> of=<root_device> bs=8M` **Problem : Mouse fails**
    * [live usb][18] (you need a live image, netinstaller does not work) 
    * `livecd-iso-to-disk --efi --format --unencrypted-home --home-size-mb 2048 --overlay-size-mb 1024 --label <LESS_than_11_chars> <live_iso> /dev/<usb>`
    * You can boot into the live system and patch xorg.conf t get the mouse working
    * less options on installation for fedora

### Backups (use `backup_cp`)

* Check examples for fstab and Xserver configs are up to date
* Export browser parameters : bookmarks
* Export emulators configs for MAME and [MEDNAFEN][1]
* Ensure handy-scripts-for-work is up to date

* Backup virtual machines disks and iso images+licences_keys
* Run a BTRFS [scrub][5] on Bifrost
* Create snapshots on Lucian_PrioA/B/C
* Create /home backup to /media/BifrostSnap/ArngrimHome
* Do an extra backup : /media/Lucian_PrioA, /media/Lucian_PrioB/Kashell



### BIOS tweaks

* Deactivate secure boot
* Deactive hyperthreading
* Adjust fan speeds
* Deactivate turbo boost for silent PC
* Disable C-state mode for cores
* Boot drives order

## Installation

* If you have trouble with mouse try `xinput --set-button-map <device> <map_button>`
* Create system partitions
    * Disable LVM
    * Create [ESP partition][4] for UEFI booting
    * ArngrimRoot (/) = 30GB, ArngrimHome (/home) = 20GB, ArngrimData (/media/ArngrimData) = everything

### Add extra software repos

* Fetch rpm repo key with `gpg --keyserver <HOST> --recv-keys <KEY_ID>`
* Import it to th rpm keyring `gpg --armor --export <KEY_ID> > temp.sig ; rpm --import temp.sig`
* Check rpm package `rpm -K <PACKAGE>`
* [rpmfusion][10] (free and non-free)
* [google-chrome][11] and [key][12]
* Configure the [priority][14] (lower is higher!) repo option in `/etc/yum.repos.d`
* Remember that the keys in `/etc/pki/rpm-gpg` are [NOT used][15] to verify pacakges !!

### Linux tweaks

* X server mouse and arcade stick configurations to /etc/X11/xorg.conf.d
* Use noop scheduler for SSD block devices
    * Manually write to /sys/block/sdX/queue/scheduler or use [udev][2]
* Set no access modification time on mount options
    * `noatime,nodiratime` but easier to adapt fstab template in this repo
* Blacklist modules (/etc/modprobe.d/<name>.conf) : pcspkr
* Set the [dirty_ratio][7] `/proc/sys/vim` for virtual memory with [sysctl][6]
* Disable or set permissive mode for [selinux][22]
* Use `systemctl analyse blame` to check [boot bottle necks][21]
* Use `/etc/mkinitcpio.conf` or `/etc/dracut.conf` to customize initial ram disk (check it with `lsinitrd or lsinitramfs`
* Enable [transparent huge pages][23] on kernel command line (check in `/sys/kernel/mm/transparent_hugepage`)

### Graphics card drivers

* [Install propietary][20] gpu kernel modules, xorg drivers, VDPAU/VAAPI
* Tweak [gpu settings][8]
* Check GPU acceleration `glxinfo | grep direct` and `vblank_mode=0 glxgears`
* Blacklist nouveau in `/etc/modprobe.d` and regenerate initramfs

### Initial ram disk : initramfs

* `man dracut` gives plenty of good advise
* Usual options : hostonly, compress=lz4, omit plymouth and fancy filesystems ...
    * compress option can make decoding of initramfs fail
* Regenerate image for running kernel with `dracut -f`

### Boot loader

* Grub options [config][3] : save last boot choice / shorten wait time / noquiet / vgamode (may conflict with gpu)
    * Prefer `GRUB_CMDLINE_LINUX_DEFAULT`, rescue mode boot options will not be changed
* Edit templates in `/etc/grub.d/10_linux` to have more descrpitive boot menu entries
* `/etc/default/grub` then `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
* Disable plymouth (graphical boot) by adding plymouth.enable=0 in kernel command line

### Distribution tweaks

* Install extra dnf plugins `dnf-plugins-extras-*`
* Add keyboard layout : map=us, layout=english(us), variant="alternative, international"
* Set the machine name on /etc/hostname
* Disable unneeded systemd units, create [tempfiles][9]
* Put user [~/.cache][13] into tmpfs
* Activate [numlock][19] on boot for tty + xorg session manager (kde => sddm)
    * Option using numlockx on Xsetup is more reliable

### Desktop environment tweaks

* KILL [KWALLET][16] !!! Double check settings in `~/.config/kwalletrc`
* Search [kde_conf][17] for an exhaustive list of settings and packages (careful based on kde4)
* Just go through the conf options manually ...
* Disable inactivity screen lock and login prompt at boot
* Restore XDG links in `~/.config/user-dirs.dirs` (point cache home to tmpfs)
* Restore symlinks in /home
    * ln -fs /media/Lucian_PrioA/MyProjects Programation
    * ln -fs /media/Lucian_PrioA/Images/
    * ln -fs /media/Lucian_PrioA/Important_Documents Documents
    * ln -fs /media/Lucian_PrioB/Emulation 
    * ln -fs /media/Lucian_PrioC/Music
    * ln -fs /media/Lucian_PrioC/Video
    * ln -fs /media/Gandar/Temp

### Software packages

* Remove utils : totem, cd-burner, konqueror 
* Remove services : drkonqi (cores at shutdown), spice-vdagent (xserver on host for virtual guest machines desktop), backuppc (pulls in httpd)
* Add themes : droid fonts, kde-gtk-config, gtk 2 and 3 theme matching KDE's (currently breeze)
* Add libraries : all gstreamer plugins, lm_sensors
* Restore virtual machines disk images to ssd storage

### Open issues

* Adjust brigthness
* dnf list/search packages with version and repo
* pending job on shutdown, looks related to kde binaries coring and [systemd coredump][24] service waiting for them
    * Shorten systemd stop timeout : `man system.conf`

[1]: http://forum.fobby.net/index.php?t=msg&goto=2082&
[2]: https://wiki.archlinux.org/index.php/Maximizing_performance#Using_udev_for_one_device_or_HDD.2FSSD_mixed_environment
[3]: https://wiki.archlinux.org/index.php/Kernel_parameters#GRUB
[4]: https://wiki.archlinux.org/index.php/EFI_System_Partition
[5]: https://wiki.archlinux.org/index.php/Btrfs#Scrub
[6]: https://wiki.archlinux.org/index.php/Sysctl#Virtual_memory
[7]: http://lwn.net/Articles/572911/
[8]: https://wiki.archlinux.org/index.php/NVIDIA#NVIDIA_Settings
[9]: https://wiki.archlinux.org/index.php/Systemd#Temporary_files
[10]: http://rpmfusion.org/Configuration
[11]: https://www.google.com/chrome/browser/desktop/index.html
[12]: https://www.google.com/linuxrepositories/
[13]: https://wiki.archlinux.org/index.php/Chromium/Tips_and_tricks#Cache_in_tmpfs
[14]: http://dnf.readthedocs.org/en/latest/conf_ref.html#repo-options
[15]: http://blog.andreas-haerter.com/2012/03/06/rpm-yum-gpg-key-verification-import-deletion-package-signature-check-cheat-sheet
[16]: http://stackoverflow.com/questions/29594260/how-to-disable-kwallet-in-kde-plasma-5/29945946
[17]: ../configuration/kde4_conf
[18]: https://fedoraproject.org/wiki/How_to_create_and_use_Live_USB#Command_line_method:_Using_the_livecd-iso-to-disk_tool_.28Fedora_only.2C_non-graphical.2C_both_non-destructive_and_destructive_methods_available.29
[19]: https://wiki.archlinux.org/index.php/Activating_Numlock_on_Bootup#Extending_getty.40.service
[20]: http://rpmfusion.org/Howto/nVidia
[21]: https://freedesktop.org/wiki/Software/systemd/Optimizations/
[22]: http://fedoraproject.org/wiki/SELinux_FAQ#How_do_I_enable_or_disable_SELinux_.3F 
[23]: https://www.kernel.org/doc/Documentation/kernel-parameters.txt
[24]: https://github.com/systemd/systemd/issues/2691

