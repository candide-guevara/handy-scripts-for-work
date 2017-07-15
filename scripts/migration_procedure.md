# Change home workstation

## Prerequisites

### New physical node

* Build it ! 
* Prepare SATA+POWER connectors for drives in the current installation

### Backups (use `backup_cp`)

* Check examples for fstab and Xserver configs are up to date
* Export browser parameters : bookmarks
* Export emulators configs for MAME and [MEDNAFEN][1]
* Ensure handy-scripts-for-work is up to date

* Backup virtual machines disks and iso images+licences_keys
* Run a BTRFS [scrub][5] on Bifrost
* Create snapshots on Lucian_PrioA/B/C
* Backup /home in /media/BifrostSnap/ArngrimHome using shell function `backup_home` (but manually snapshot)
    * check you can restore your ssh keys
    * check you can restore `.bash_history`
* Do an extra backup : /media/Lucian_PrioA, /media/Lucian_PrioB



### BIOS tweaks

* Deactivate secure boot
* Deactive hyperthreading
* Adjust fan speeds
* Deactivate turbo boost for silent PC
* Disable C-state mode for cores
* Boot drives order

## Installation

* If you have trouble with mouse try `xinput --set-button-map <device> <map_button>`
    * If live image boot fails try safe graphical boot option (or in grub remove modeset)
* Create system partitions
    * Disable LVM
    * Create [ESP partition][4] for UEFI booting
    * ArngrimRoot (/) = 30GB, ArngrimHome (/home) = 20GB, ArngrimData (/media/ArngrimData) = everything

### Add extra software repos

* Fetch rpm repo key with `gpg --keyserver <HOST> --recv-keys <KEY_ID>`
* Import it to th rpm keyring `gpg --armor --export <KEY_ID> > temp.sig ; rpm --import temp.sig`
* Check rpm package `rpm -K <PACKAGE>`
* [rpmfusion][10] (free and non-free)
* Configure the [priority][14] (lower is higher!) repo option in `/etc/yum.repos.d`
* Remember that the keys in `/etc/pki/rpm-gpg` are [NOT used][15] to verify pacakges !!
* [google-chrome][11] and [key][12]
  * Or use firefox with extensions "Dark Background and Light Text" and "Zoom Page" (tweak also min font size setting)

### Linux tweaks

* Add your user to the `/etd/sudoers.d` file and set option to ask password
* Use noop scheduler for SSD block devices
    * Manually write to /sys/block/sdX/queue/scheduler or use [udev][2]
* Set no access modification time on mount options
    * `noatime,nodiratime` but easier to adapt fstab template in this repo
* Use `hdparm -I  --dco-identify /dev/sd?` to query (or change if supported) the advanced power mgt and acoustic mgt 
* Blacklist modules (/etc/modprobe.d/<name>.conf) : pcspkr
* Set the [dirty_ratio][7] `/proc/sys/vim` for virtual memory with [sysctl][6]
* Disable or set permissive mode for [selinux][22]
* Use `man tmpfiles.d` to set some configuration
  * Enable performance [cpufreq][26] governor by writing "performance" to /sys/devices/system/cpu/cpu\*/cpufreq/scaling\_governor
  * Enable bpf jit for [seccomp][27] filter by writing "1" to /proc/sys/net/core/bpf\_jit\_enable

* Use `systemctl analyse blame` to check [boot bottle necks][21]

### Xorg, Graphics card drivers

* X server mouse and arcade stick configurations to /etc/X11/xorg.conf.d
* [Install propietary][20] gpu kernel modules, xorg drivers, VDPAU/VAAPI
* Tweak [gpu settings][8]
* Check GPU acceleration `glxinfo | grep direct` and `vblank_mode=0 glxgears`
* Blacklist nouveau in `/etc/modprobe.d` and regenerate initramfs

### Initial ram disk : initramfs

* Use `/etc/mkinitcpio.conf` or `/etc/dracut.conf` to customize initial ram disk (check it with `lsinitrd or lsinitramfs`
* `man dracut` gives plenty of good advise
* Usual options : hostonly, compress=lz4, omit plymouth and fancy filesystems ...
    * compress option can make decoding of initramfs fail
    * WARNING : dracut.conf has a very strict syntax **no space between `=` and values enclosed in double-qoutes**
* Regenerate image for running kernel with `dracut -f`
* Check disk contents with `lsinitrd or lsinitramfs`

### Boot loader

* Grub options [config][3] : save last boot choice / shorten wait time / noquiet / remove rhgb (red hat graphical boot)
    * Prefer `GRUB_CMDLINE_LINUX_DEFAULT`, rescue mode boot options will not be changed
* `/etc/default/grub` then `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
* Disable plymouth (graphical boot) by adding plymouth.enable=0 in kernel command line
* Enable [transparent huge pages][23] on kernel command line (check in `/sys/kernel/mm/transparent_hugepage`)
* Disable nmi watchdog on [kernel command line][23]

### Distribution tweaks

* Install extra dnf plugins `dnf-plugins-extras-*`
* Add keyboard layout : map=us, layout=english(us), variant="alternative, international"
* Set the machine name on /etc/hostname
* Set a public DNS on network manager, you need to create a new connection profile and **drop the default one**
    * Test using `dig +trace www.google.com`, check `/etc/resolv.conf` too
* Disable unneeded systemd units 
    * disable firewalld, sssd, auditd, bluetooth
    * mask `sshd`
* Put user [~/.cache][13] into tmpfs
* Activate [numlock][19] on boot for tty + xorg session manager (kde => sddm)
    * Option using numlockx on Xsetup is more reliable
* If you are using ccache, change the default cache directory to a tmpfs location (see ccache man's page)    
* Configure pulse audio options (cf `man pulse-daemon.conf`)
    * Change [sample depth and rate][25] (default and alternate), chose soxr-vhq for resampling
    * Do not load useless modules (filters, bluetooth ...)
    * If using external amplifier you can blacklist all onboard-sound kernel modules in `/etc/modprobe.d`
    * Change `nice` and `rtprio` limits for my user in `/etc/security/limits.d` so that pulse daemon has lower latency

### Notebook specific tweaks

* [backlight adjust][28] either directly on /sys, using udev, or systemd
* settings in `/etc/default/tlp` and check it is working by unplugging power and check settings have changed`

### Software packages

* Remove utils : totem, cd-burner, konqueror 
* Remove services : drkonqi (cores at shutdown), spice-vdagent (xserver on host for virtual guest machines desktop), backuppc (pulls in httpd)
* Add themes : droid fonts, kde-gtk-config, gtk 2 and 3 theme matching KDE's (currently breeze)
* Add libraries : all gstreamer plugins, lm_sensors
* Restore virtual machines disk images to ssd storage

### Desktop environment tweaks

* KILL [KWALLET][16] !!! Double check settings in `~/.config/kwalletrc`
* Search [kde_conf][17] for an exhaustive list of settings and packages (careful based on kde4)
* Just go through the conf options manually ...
* Disable inactivity screen lock and login prompt at boot
* Restore XDG links in `~/.config/user-dirs.dirs` (point cache home to tmpfs)
* Check bind mounts in `fstab` are configured for quick access from /home

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
[19]: https://wiki.archlinux.org/index.php/Activating_Numlock_on_Bootup#Extending_getty.40.service
[20]: http://rpmfusion.org/howto/nvidia
[21]: https://freedesktop.org/wiki/software/systemd/optimizations/
[22]: http://fedoraproject.org/wiki/SELinux_FAQ#How_do_I_enable_or_disable_SELinux_.3F 
[23]: http://static.lwn.net/kerneldoc/admin-guide/kernel-parameters.html
[24]: https://github.com/systemd/systemd/issues/2691
[25]: http://r3dux.org/2013/12/how-to-enable-high-quality-audio-in-linux/
[26]: https://wiki.archlinux.org/index.php/CPU_frequency_scaling#Scaling_governors
[27]: https://lwn.net/Articles/656307/
[28]: https://wiki.archlinux.org/index.php/backlight

