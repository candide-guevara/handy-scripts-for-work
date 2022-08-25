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
pacman -R `pacman -Qqs linux-latest ; pacman -Qqs linux-lts`

mhwd-kernel -li # get kernel versions installed
pacman -S `pacman -Qqs "linux<old>" | sed 's/<old>/<new>/'`

# Check mhwd does not have unneeded old drivers
# Package names appearing on the first col can be removed
comm -1 <(pacman -Qqs mhwd|sort) <(pactree --depth=1 --unique mhwd-db|sort)

# Check latest kernel dependent modules are installed
# Package names appearing on the second col must be updated
comm -3 \
  <(pacman -Ss "linux<old>" | sed -nr 's"^\w+/""p' | cut -d' ' -f1,2 | sort) \
  <(pacman -Qs "linux<new>" | sed -nr 's"^\w+/""p' | cut -d' ' -f1,2 | sort)

pacman -R `pacman -Qqs "linux<old>"`
```

## Upgrade system

```sh
pacman -Sy archlinux-keyring manjaro-keyring
pacman -Scc
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
( vainfo ; vdpauinfo ; vulkaninfo ; glxinfo | grep direct ) | less
```

## You do not need the following:

* `libxnvctrl` used to overclock nvidia GPU (similar to GWE aka GreenWithEnvy)
* `linux*-acpi_call`,`linux*-bbswitch` issue acpi calls by writing to /proc

