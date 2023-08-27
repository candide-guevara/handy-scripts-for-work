## Attempts to fix age of empires 2 multiplayer.
source common.sh || exit 2

# see https://github.com/ValveSoftware/Proton/issues/3189#issuecomment-1610974028
tweak_encryption_validation_lib() {
  pushd /tmp
  git clone git://source.winehq.org/git/wine.git
  cd wine
  ./configure CFLAGS="-march=native -O3 -pipe -fstack-protector-strong" --enable-win64
  cd dlls/wintrust
  sed -ri 's/(if \(IsEqualGUID\(ActionID, &published_software\)\))/if(1) { err = 0; } else \1/' wintrust_main.c
  make
  popd
  pushd "$PROTON_ROOT"
  mv dist/lib64/wine/x86_64-windows/wintrust.dll dist/lib64/wine/x86_64-windows/broken_wintrust.broken
  cp -f /tmp/wine/dlls/wintrust/x86_64-windows/wintrust.dll dist/lib64/wine/x86_64-windows/wintrust.dll
  popd
}

# see https://forums.ageofempires.com/t/skipping-intro-video-of-aoe2-hd-and-de-upon-launch-for-steam/81525
set_skip_intro_in_launch_opts() {
  echo "[ERROR] set SKIPINTRO cannot be done manually :/"
}

set_environment_vars "813780" AoE2DE

patch_visual_studio_runtime_2015 ucrtbase
# https://www.reddit.com/r/aoe2/comments/dwuplr/how_to_run_age_of_empires_2_definitive_edition_on/
# latest guide: https://aoe2.arkanosis.net/linux/#aoe2_de_online_multiplayer
# apparently this must be run after the game is launched once?
rename_game_data_dir_matching movies 
tweak_encryption_validation_lib
#copy_user_settings
echo "ALL DONE"

