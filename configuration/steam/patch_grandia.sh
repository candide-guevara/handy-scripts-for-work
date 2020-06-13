## Some fixes for grandia HD so that it plays on linux

STEAM_LIB_ROOT='/media/llewelyn_data_b/SteamLibrary'
GAME_ROOT="$STEAM_LIB_ROOT/steamapps/common/GRANDIA HD Remaster"
EMU_CDRIVE_ROOT="$STEAM_LIB_ROOT/steamapps/compatdata/1034860/pfx/drive_c"
USER_CFG_ROOT="$EMU_CDRIVE_ROOT/users/steamuser/Application Data/GRANDIA1"
PREFIX=zzz__
SUFFIX=.bk

# https://www.gamesdatabase.org/Media/SYSTEM/Sony_Playstation//Manual/formated/Grandia_-_1999_-_Sony_Computer_Entertainment.pdf
# https://www.pcgamingwiki.com/wiki/Grandia_HD_Remaster#/media/File:Grandia_HD_Keyboard_Bindings.png
# https://wiki.libsdl.org/SDL_Keycode
# 7 8 9 10  : up down left right
# 0 1 2 3   : cross circle square triangle
# 4 5 11 12 : L1 R1 L2 R2
# 6 13 : start ???
CONFIG_INI="gamepad_mapping0=1
gamepad_mapping1=2
gamepad_mapping11=7
gamepad_mapping12=8
gamepad_mapping13=6
gamepad_mapping2=3
gamepad_mapping3=4
gamepad_mapping4=9
gamepad_mapping5=10
gamepad_mapping6=5
gamepad_mapping7=15
gamepad_mapping8=16
gamepad_mapping9=13
gamepad_mapping10=14
japanese_audio=true
keyboard_mapping0=Keypad 2
keyboard_mapping1=Keypad 3
keyboard_mapping2=Keypad 1
keyboard_mapping3=Keypad 5
keyboard_mapping4=Keypad 4
keyboard_mapping5=Keypad 6
keyboard_mapping6=Space
keyboard_mapping7=W
keyboard_mapping8=S
keyboard_mapping9=A
keyboard_mapping10=D
keyboard_mapping11=Keypad 7
keyboard_mapping12=Keypad 8
keyboard_mapping13=Keypad 0
music_volume=80
pause_on_focus_lost=true
sfx_volume=70
text_language=0
video_antialiasing=1
video_fullscreen=false
video_resolution_x=1920
video_resolution_y=1080"

#cf https://steamcommunity.com/app/1034860/discussions/0/3342162929523389763/
patch_launcher() {
  local launcher="launcher.exe"
  local launcher_bk="${launcher}.bk"
  local gamebin="grandia.exe"

  pushd "$GAME_ROOT"
    if [[ ! -f "$gamebin" ]]; then
      echo "[ERROR] game  bin '$gamebin' not found"
      return 1
    fi
    [[ ! -L "$launcher" ]] && [[ -f "$launcher" ]] && mv "$launcher" "$launcher_bk"
    ln -s "$gamebin" "$launcher"
  popd
}

#cf https://www.pcgamingwiki.com/wiki/Grandia_HD_Remaster
patch_config() {
  local config="config.ini"
  local config_bk="config.ini.`date +%s`.bk"
  pushd "$USER_CFG_ROOT"
    mv "$config" "$config_bk"
    echo "$CONFIG_INI" > "$config"
    unix2dos "$config"
  popd
}

# https://steamcommunity.com/app/1034860/discussions/0/1606022547917842813/
remove_smooth_sprites() {
  pushd "$GAME_ROOT/content/FIELD"
    local touched_files="touched_files.`date +%s`.txt"
    # if you include the "map" sprites, some glitches will occur
    find -type f -print0 | grep -z 'spriteinfo.bin$' | grep -zv 'map' | sed -zr 's"^\./""' \
      | tee "$touched_files" \
      | xargs -0 -I{} mv '{}' "${PREFIX}{}${SUFFIX}"
  popd
  pushd "$GAME_ROOT/content/BATLE"
    local touched_files="touched_files.`date +%s`.txt"
    find -type f -print0 | grep -z '.tpk$' | sed -zr 's"^\./""' \
      | tee "$touched_files" \
      | xargs -0 -I{} mv '{}' "${PREFIX}{}${SUFFIX}"
  popd
  pushd "$GAME_ROOT/content/BIN"
    local target="pgmdt_pgmdt__spriteinfo.bin"
    [[ -f "$target" ]] && mv "$target" "${PREFIX}${target}${SUFFIX}"
  popd
}

unremove_smooth_sprites() {
  for dd in "$GAME_ROOT/content/FIELD" "$GAME_ROOT/content/BATLE" "$GAME_ROOT/content/BIN"; do
  pushd "$dd"
    local touched_files="untouched_files.`date +%s`.txt"
    find -type f -print0 | grep -zE "^${PREFIX}.*${SUFFIX}\$" | sed -zr "s'^\./$PREFIX''"  | sed -zr "s'$SUFFIX''" \
      | tee "$touched_files" \
      | xargs -0 -I{} mv "${PREFIX}{}${SUFFIX}" '{}'
  popd
  done
}

patch_launcher
#patch_config
remove_smooth_sprites
#unremove_smooth_sprites

