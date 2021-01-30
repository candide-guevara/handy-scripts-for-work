# Archlinux upgrade procedure

> Should I remove `mhwd` ? It just reinstalls the video driver on system update.

## Enable internet in rescue mode

```sh
systemctl start NetworkManager
nmcli device wifi list
nmcli device wifi connect "<network name>"
ping google.com
```

## Remove kernel dependent modules

```sh
mhwd-kernel -li # get kernel versions installed
pacman -Qqs "linux<version>"
pacman -Qqs linux-latest #linux-lts
pacman -Qqs nvidia | grep -E '\d+xx'
pacman -R "<packages found>"
```

## Upgrade system

```sh
pacman -Scc
pacman -Syyu
```

## Reinstall kernel dependent modules

```sh
pacman -S linux-latest-nvidia
pacman -S linux-latest-virtualbox-host-modules
pacman -S opencl-nvidia nvidia-utils # also their 32bit versions
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

## After reboot remove old kernels

```sh
mhwd-kernel -r "old_kernel"
```

