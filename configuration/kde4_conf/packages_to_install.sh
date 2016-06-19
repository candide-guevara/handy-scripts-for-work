# Before setting the config at least these packages must be installed

# Themes, icons, fonts
packages=( gtk2-engine-oxygen gtk2-theme-oxygen gtk3-engine-oxygen gtk3-theme-oxygen 
  oxygen-icon-theme oxygen-icon-theme-large oxygen-icon-theme-scalable
  yast2-theme-openSUSE-Oxygen 
  gtk2-metatheme-adwaita gtk3-metatheme-adwaita 
  libreoffice-icon-theme-oxygen 
  metatheme-adwaita-common
  google-droid-fonts liberation-fonts dejavu-fonts cantarell-fonts bitstream-vera-fonts )
zypper install --no-recommends ${packages[@]}

# Google chrome (nice addon hacker vision)
# Visit https://www.google.com/chrome/browser/desktop/
rpm --checksig -v google-chrome-stable_current_x86_64.rpm
rpm --help
zypper install lsb
rpm -i google-chrome-stable_current_x86_64.rpm
zypper install --no-recommends google-chrome-stable

# Remove kwallet
zypper remove --clean-deps kwalletmanager

# Other software
zypper install --no-recommends kdebase4-workspace-ksysguardd
zypper install --no-recommends vlc vlc-codecs vlc-qt ffmpeg libva1


