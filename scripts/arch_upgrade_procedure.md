# Archlinux upgrade procedure

> Should I remove `mhwd` ? You need this to auto upgrade nvidia drivers !

## Run commands without exiting vim

Yank the command, enter command mode and use `CTRL-R "`

## Enable internet in rescue mode

```sh
systemctl start NetworkManager
nmcli device wifi list
nmcli device wifi connect "<network name>"
ping google.com
```

## Remove/Install new kernel

```sh
# "latest" packages are no longer used, drop them
pacman -Rsun `pacman -Qqs linux-latest ; pacman -Qqs linux-lts`

old_vers=61
new_vers=66
mhwd-kernel -li # get kernel versions installed
pacman -S `pacman -Qqs "linux$old_vers" | sed "s/$old_vers/$new_vers/"`

# Check mhwd does not have unneeded old drivers
# Package names can be removed
comm -13 <(pacman -Qqs mhwd|sort) <(pactree --depth=1 --unique mhwd-db|sort)

# Check latest kernel dependent modules are installed
# Package names appearing col must be updated
comm -13 \
  <(pacman -Qs "linux$old_vers" | sed -nr 's"$old_vers"$new_vers"; s"^\w+/""p' | cut -d' ' -f1 | sort) \
  <(pacman -Qs "linux$new_vers" | sed -nr 's"^\w+/""p' | cut -d' ' -f1 | sort)

pacman -Rsun `pacman -Qqs "linux$old_vers"`
```

## Upgrade system

```sh
pacman -Sy archlinux-keyring manjaro-keyring
pacman -Scc && pacman -Syyuw
# Install updates in rescue mode
# systemctl rescue
# pacman -Su

# For nvidia prefer vdpau
# See https://wiki.archlinux.org/title/Hardware_video_acceleration
pacman -S {lib32-,}libva {lib32-,}libva-vdpau-driver {lib32-,}mesa-vdpau libva-utils libvdpau-va-gl
pacman -S {lib32-,}opencl-nvidia {lib32-,}nvidia-utils {lib32-,}mesa-utils
```

## Upgrade AUR packages

```sh
pacman -Qq --foreign # list other packages besides AUR
pushd "aur package git repo"
git pull
makepkg
sudo pacman -U "<generated_package>"
```

## After reboot checks

```sh
uname -a
( vainfo ; vdpauinfo ; vulkaninfo ; glxinfo | grep direct ) | less
```

## You do not need the following:

* `libxnvctrl` used to overclock nvidia GPU (similar to GWE aka GreenWithEnvy)
* `linux*-acpi_call`,`linux*-bbswitch` issue acpi calls by writing to /proc

