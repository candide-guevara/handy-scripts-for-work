# Change home workstation

## Prerequisites

### New physical node

* Build it ! 
* Prepare SATA+POWER connectors for drives in the current installation

### Backups (use `backup_cp`)

* Check examples for fstab and Xserver configs are up to date
* Export browser parameters : bookmarks
* Backup virtual machines disks and iso images+licences_keys
* Backup **encrypted** `/etc` in /media/BifrostSnap/ArngrimHome 
* Ensure git repo modifs are all commited and pushed to github (run `git_check_all_pushed`)

* Run a BTRFS [scrub][5] on Bifrost
* Create snapshots on Lucian_PrioA/B/C
* Backup /home in /media/BifrostSnap/ArngrimHome using shell function `backup_home` (but manually snapshot)
  * check you can restore your ssh keys
  * check you can restore `.bash_history`
* Do an extra backup (seprate usb key, laptop ...) : /media/Lucian_PrioA, /media/Lucian_PrioB



### BIOS tweaks

* Deactivate secure boot
* Deactive hyperthreading
* Adjust fan speeds
* Deactivate turbo boost for silent PC
* Disable C-state mode for cores
* Boot drives order

## Installation

* Boot installation media in **UEFI mode** : otherwise installer will put grub in MBR
* If you have trouble with mouse try `xinput --set-button-map <device> <map_button>`
  * If live image boot fails try safe graphical boot option (or in grub remove modeset)
* Create system partitions
  * Disable LVM
  * Create [ESP partition][4] for UEFI booting
  * ArngrimRoot (/) = 30GB, ArngrimHome (/home) = 20GB, ArngrimData (/media/ArngrimData) = everything else
  * Filesystems should be labelled (use `e2label` and `fat2label`)

### Add extra software repos (fedora only)

* Fetch rpm repo key with `gpg --keyserver <HOST> --recv-keys <KEY_ID>`
* Import it to the rpm keyring `gpg --armor --export <KEY_ID> > temp.sig ; rpm --import temp.sig`
* Check rpm package `rpm -K <PACKAGE>`
  * [rpmfusion][10] (free and non-free)
  * [google-chrome][11] and [key][12]
    * Or use firefox with extensions "Dark Background and Light Text" (other extensions are too slow)
* Configure the [priority][14] (lower is higher!) repo option in `/etc/yum.repos.d`
* Remember that the keys in `/etc/pki/rpm-gpg` are [NOT used][15] to verify packages !!

### Linux tweaks

* Add your user to the `/etd/sudoers.d` file and set option to ask password
  * `Defaults   rootpw <br/>cguevara        ALL=(ALL)       ALL`
* Use noop scheduler for SSD block devices
  * Manually write to `/sys/block/*/queue/scheduler` or use [udev][2]
* Set no access modification time on mount options
  * `noatime,nodiratime` but easier to adapt fstab template in this repo
* If using LVM restrict device scanning by setting filter patterns on `/etc/lvm/lvm.conf`
* Use `hdparm -I  --dco-identify /dev/sd?` to query (or change if supported) the advanced power mgt and acoustic mgt 
* Blacklist modules (/etc/modprobe.d/<name>.conf) : pcspkr
* Set the [dirty_ratio][7] `/proc/sys/vim` for virtual memory with [sysctl][6]
* Disable or set permissive mode for [selinux][22]
* Use `man tmpfiles.d` to set some configuration
  * Enable performance [cpufreq][26] governor by writing "performance" to /sys/devices/system/cpu/cpu\*/cpufreq/scaling\_governor
  * Enable bpf jit for [seccomp][27] filter by writing "1" to /proc/sys/net/core/bpf\_jit\_enable

### [Huge pages][39]

* Install libhugetlbfs package (AFAIK only available on AUR)
* Mask default hugepage mountpoint (not accessible to user) `systemctl mask dev-hugepages.mount`
* Use `man tmpfiles.d` to set `/sys/kernel/mm/transparent_hugepage/*enabled`
* Install [custom service unit][40] to configure hugepages at boot
  * Check : `mount | grep huge ; grep thp /proc/vmstat ; grep -i huge /proc/meminfo ; cat /proc/sys/vm/hugetlb_shm_group`
  * Alternative method using : `find /sys/kernel/mm/transparent_hugepage /sys/kernel/mm/hugepages -type f -print0 | xargs -0tL1 cat`

* Use `systemd-analyze && systemd-analyze blame` to check [boot bottle necks][21]

### Xorg, Graphics card drivers

* X server mouse and arcade stick configurations to /etc/X11/xorg.conf.d
* [Install propietary][20] gpu kernel modules, xorg drivers
  * Nvidia cards use the [VDPAU API for video decoding][30] : use `vdpauinfo` to see it is accessible
  * Intel cards use VAAPI : it can be emulated by `libva-vdpau`, use `vainfo` to see it is accessible
* Check GPU acceleration `glxinfo | grep direct` and `__GL_SYNC_TO_VBLANK=0 vblank_mode=0 glxgears` (last result 1070=28000 FPS)
* Go to `/etc/X11/xorg.conf.d/*` and check for overconfigured files -> leave a [minimal gpu config][36] with ["IgnoreDisplayDevices" option][35]
* If HDMI does not work on QHD : (still not sure of instructions)
  * plug using displayport and hdmi
  * check nvidia control app sees both
  * disable DP and enable HDMI -> **quickly (before 5 secs) unplug DP**
  * make sure hdmi is configured at 60hz on monitor
* use `xrandr` to know the connected ports (and refresh rate marked with `*`)

### Boot loader

* Grub options [config][3] 
  * save last boot choice / shorten wait time / noquiet / remove rhgb (red hat graphical boot)
* Set kernel boot params in `GRUB_CMDLINE_LINUX_DEFAULT` (rescue mode boot options will not be changed)
  * [Security vulnerabilities mitigations][43] (and [this one][29]): check which ones can be disabled for perf
    * As of this writing `nospectre_v1 spectre_v2=off nopti mds=off spec_store_bypass_disable=off`
    * Check `/sys/devices/system/cpu/vulnerabilities/*` (you should be vulnerable now)
  * Disable plymouth (graphical boot) by adding plymouth.enable=0 in kernel command line
  * Disable `nmi_watchdog=0` on [kernel command line][23] if `grep -i nmi /proc/interrupts` has a high count
  * Disable [kauditd][44] `audit=0`
  * Looks for other options in article [hunting linux boot errors][42]
* `/etc/default/grub` then `grub-mkconfig -o /boot/grub/grub.cfg`

### Distribution tweaks

* Install extra dnf plugins `dnf-plugins-extras-*`
* Add keyboard layout : map=us, layout=english(us), variant="alternative, international"
* Set the machine name on /etc/hostname
* Set a public DNS on network manager, you need to create a new connection profile and **drop the default one**
  * Test using `dig +trace www.google.com`, check `/etc/resolv.conf` too    
  * Use `ethtool` to validate autonegotiation is active => otherwise we may have a slow connection
  * If connection slow try removing and reloading network kernel module (`alx`)
* Disable unneeded systemd units 
  * disable iptables, ip6tables, firewalld, sssd(NOT a typo), sshd (service), bluetooth, avahi-daemon (service and socket)
  * mask sshd@, sshd.socket, systemd-journald-audit.socket
* Make sshd a bit more secure
  * create iptable rules to only allow ssh connection from home network in `/etc/iptables/(ip|ip6)tables.rules`
  * tweak the sshd.service unit to depend on [systemd-iptables][8] so that iptable kernel module is only loaded when opening sshd
* Put user [~/.cache][13] into tmpfs
  * Check `/tmp` is also under tmpfs
* Activate [numlock][19] on boot for tty 
  * Activate for xorg session manager (kde => sddm) with kde gui
  * If fails, option using numlockx on Xsetup is more reliable
* If you are using ccache, change the default cache directory to a tmpfs location (see ccache man's page)    
* Configure pulse audio options (cf `man pulse-daemon.conf`)
  * Change [sample depth and rate][25] (default and alternate), chose soxr-vhq for resampling
  * Do not load useless modules (filters, bluetooth ...) in `~/.config/pulse/default.pa`
  * Avoid annoying pops by [unloading suspend mod][38], check module was not loaded with `pacmd ls`
  * If using external amplifier you can blacklist all onboard-sound kernel modules (like `snd_hda_intel`) in `/etc/modprobe.d`
  * Disable alsa restore udev rule by creating the relevant symlink to `/dev/null` in `/etc/udev/rules.d`
  * Use `pactl list` to check options are setup ok
* There are too many option for power management : powerdevil, acpid, sytemd-logind, TLP, upower...
  * pick one and disable the others (via systemd services ?)
  * Make sure there are no actions that can suspend/sleep the system in `/etc/systemd/logind.conf`

### Notebook specific tweaks

* [backlight adjust][28] with `man tmpfiles.d`
  * you need to mask systemd backlight service
* settings in `/etc/default/tlp` and check it is working by unplugging power and check settings have changed

### Software packages

* Remove utils : totem, cd-burner, konqueror 
* Remove services : 
  * drkonqi (cores at shutdown), spice-vdagent (xserver on host for virtual guest machines desktop), backuppc (pulls in httpd)
  * kdeconnect (listens at everything on port 1716)
  * octopi (crashes Xserver) : `pacman -Qsq octopi | sudo pacman -Rnsu -`
* Add themes : droid fonts, kde-gtk-config, gtk 2 and 3 theme matching KDE's (currently breeze)
* Activate hardware sensors : install `lm_sensors` and run `sensors-detect` (will active systemd unit)
* Restore virtual machines disk images to ssd storage
* Check [`.config/chrome-flags.conf`][33] was installed by private-handy-scripts-for-work
  * [hardware acceleration][37] can be checked by going to `chrome://gpu/`
  * Some testing with 1080p60 on youtube shows cpu video decode works perfectly fine anyway
* Install [retroarch][34] and reate `~/.config/retroarch/retroarch.cfg`
  * Use online updater to get **assets** to have icons

### Desktop environment tweaks

* KILL [KWALLET][16] !!! Double check settings in `~/.config/kwalletrc`
* Restore XDG links in `~/.config/user-dirs.dirs` (point cache home to tmpfs)
* Check bind mounts in `fstab` are configured for quick access from /home
* Just go through system settings GUI manually ...
  * Disable sound by installing `pavucontrol-qt` and set notification volume to sero **then** mute
  * Disable inactivity screen lock and login prompt at boot
  * Disable kde file search (install mlocate instead)
* Configure the task bar
* Set gpg [password prompt][31] to ncurses on `~/.gnupg/gpg-agent.conf`
  * Reduce the time to live for gpg passwords
* Run `ss -pltun` and `sudo lsof -nPi` to detect listening ports, remove any application opening ports (ex avahi)
* Create a [polkit rule][32] in `/etc/polkit-1/rules.d` to avoid udisks2 (used by Dolphin) to mount arbitrary devices
* Create [window rule][45] to not show title bars (gets back a bit of screen real state)

### Initial ram disk : initramfs

Do this at the end since it may take into account any blacklisted modules

* If using dracut
  * WARNING : dracut.conf has a very strict syntax **no space between `=` and values enclosed in double-qoutes**
  * `man dracut` gives plenty of good advise on `/etc/dracut.conf`
  * Usual options : hostonly, omit plymouth and fancy filesystems ...
  * Regenerate image for running kernel with `dracut -f`
* If using mkinitcpio
  * Check `/etc/mkinitcpio.conf` for any unneeded hooks, (we **want** autodetect)
  * Recreate using the preset in `/etc/mkinitcpio.d`
* Check disk contents with `lsinitrd`, `lsinitramfs`, `lsinitcpio`
  * check there are none unwanted modules like `nouveau`


### Open issues

* notification daemon call fail on dbus
* why did alx module suddenly started failing ?

### Stuff I am testing

* `/etc/systemd/sleep.conf.d/99-mycustom.conf`
* `/etc/modprobe.d/sound.conf`

[1]: http://forum.fobby.net/index.php?t=msg&goto=2082&
[2]: https://wiki.archlinux.org/index.php/Maximizing_performance#Using_udev_for_one_device_or_HDD.2FSSD_mixed_environment
[3]: https://wiki.archlinux.org/index.php/Kernel_parameters#GRUB
[4]: https://wiki.archlinux.org/index.php/EFI_System_Partition
[5]: https://wiki.archlinux.org/index.php/Btrfs#Scrub
[6]: https://wiki.archlinux.org/index.php/Sysctl#Virtual_memory
[7]: http://lwn.net/Articles/572911/
[8]: https://wiki.archlinux.org/index.php/iptables#Configuration_and_usage
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
[29]: https://wiki.ubuntu.com/SecurityTeam/KnowledgeBase/Variant4
[30]: https://wiki.archlinux.org/index.php/Hardware_video_acceleration#Verification
[31]: https://wiki.archlinux.org/index.php/GnuPG#pinentry
[32]: https://wiki.archlinux.org/index.php/Polkit#Authorization_rules
[33]: https://wiki.archlinux.org/index.php/Chromium/Tips_and_tricks#Making_flags_persistent
[34]: https://wiki.archlinux.org/index.php/RetroArch#Configuration
[35]: http://download.nvidia.com/XFree86/Linux-x86_64/396.54/README/xconfigoptions.html
[36]: https://wiki.archlinux.org/index.php/NVIDIA/Tips_and_tricks#Manual_configuration
[37]: https://wiki.archlinux.org/index.php/chromium#Force_GPU_acceleration
[38]: https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Pops_when_starting_and_stopping_playback
[39]: https://lwn.net/Articles/376606/
[40]: ../configuration/systemd/huge_pages.service
[41]: https://www.kernel.org/doc/Documentation/vm/transhuge.txt
[42]: https://candide-guevara.github.io/cs_related/linux/2020/04/12/linux-hunting-boot-log-errors.html
[43]: https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/index.html
[44]: https://wiki.archlinux.org/index.php/Audit_framework
[45]: https://docs.kde.org/trunk5/en/kde-workspace/kcontrol/windowspecific/kwin-rule-editor.html

