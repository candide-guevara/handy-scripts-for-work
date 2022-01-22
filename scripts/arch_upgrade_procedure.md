# Archlinux upgrade procedure

> Should I remove `mhwd` ? You need this to auto upgrade nvidia drivers !

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
pacman -R `pacman -Qqs linux-latest ; pacman -Qqs linux-lts`

mhwd-kernel -li # get kernel versions installed
pacman -R `pacman -Qqs "linux<version_to_remove>"`
pacman -S `pacman -Qqs "linux<version_to_remove>" | sed 's/<version_to_remove>/<version_to_add>/'`

# Check mhwd does not have unneeded old drivers
# Package names appearing on the first col can be removed
comm -1 <(pacman -Qqs mhwd|sort) <(pactree --depth=1 --unique mhwd-db|sort)

# Check latest kernel dependent modules are installed
# Package names appearing on the second col must be updated
comm -3 \
  <(pacman -Ss linux515 | sed -nr 's"^\w+/""p' | cut -d' ' -f1,2 | sort) \
  <(pacman -Qs linux515 | sed -nr 's"^\w+/""p' | cut -d' ' -f1,2 | sort)
```

## Upgrade system

```sh
pacman -Scc
pacman -Syyu
pacman -S `echo opencl-nvidia nvidia-utils mesa-utils | sed -r 's/(.*)/\1 lib32-\1/'
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
vainfo | less
vdpauinfo | less
vulkaninfo | less
glxinfo | grep direct
```

## You do not need the following:

* `libxnvctrl` used to overclock nvidia GPU (similar to GWE aka GreenWithEnvy)
* `linux*-acpi_call`,`linux*-bbswitch` issue acpi calls by writing to /proc

