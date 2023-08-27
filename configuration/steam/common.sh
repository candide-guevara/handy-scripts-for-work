## Common routines used by steam patch scripts.
STEAM_LIB_ROOT='/media/llewelyn_data_b/SteamLibrary'
VS_RUNTIME_DOWN_SRV="aka.ms"
#PROTON_ROOT="$STEAM_LIB_ROOT/steamapps/common/Proton 5.13"
PROTON_ROOT="$STEAM_LIB_ROOT/steamapps/common/Proton 8.0"
# Works for both 5 and 6 version of runtime
CURRENT_PROTON_SETTINGS="user_settings_5_13.py"

set_environment_vars() {
  local steam_id="$1"
  local game_name="$2"
  export GAME_ROOT="$STEAM_LIB_ROOT/steamapps/common/$game_name"
  export EMU_CDRIVE_ROOT="$STEAM_LIB_ROOT/steamapps/compatdata/$steam_id/pfx/drive_c"

  [[ -d "$GAME_ROOT" ]] || exit 1
  [[ -d "$EMU_CDRIVE_ROOT" ]] || exit 1
}

check_bin() {
  if ! which "$1"; then
    echo "[ERROR] '$1' not found"
    exit 1
  fi
}

check_bin_needed() {
  check_bin cabextract
  check_bin wget
}
check_bin_needed

verify_cert() {
  local server="$1"
  local tmp_openssl_out="`mktemp`"
  openssl s_client -brief -showcerts -no_ssl3 -connect "${server}:443" 2> "$tmp_openssl_out"  <<< 'Q'
  if ! grep 'Verification: OK' "$tmp_openssl_out"; then
    echo "[ERROR] $DOWNLOAD_SRV is not trusted, abort"
    exit 1
  fi
}
verify_cert "$VS_RUNTIME_DOWN_SRV"
verify_cert "download.microsoft.com"

patch_visual_studio_runtime_2015() {
  local copy_filter_rx="${1:-'.*'}"
  patch_visual_studio_runtime_helper \
    "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe" \
    "$copy_filter_rx"
}

patch_visual_studio_runtime_2017() {
  patch_visual_studio_runtime_helper "https://$VS_RUNTIME_DOWN_SRV/vs/15/release/vc_redist.x64.exe"
}

patch_visual_studio_runtime_2019() {
  patch_visual_studio_runtime_helper "https://$VS_RUNTIME_DOWN_SRV/vs/16/release/vc_redist.x64.exe"
}

patch_visual_studio_runtime_2022() {
  patch_visual_studio_runtime_helper "https://$VS_RUNTIME_DOWN_SRV/vs/17/release/vc_redist.x64.exe"
}

#cf https://steamcommunity.com/app/813780/discussions/3/3938911974192987545/
#cf https://github.com/Winetricks/winetricks/blob/master/src/winetricks
patch_visual_studio_runtime_helper() {
  local download_url="$1"
  local copy_filter_rx="${2:-'.*'}"
  local tmp_cabextracted="`mktemp -d`"
  local system32_dir="$EMU_CDRIVE_ROOT/windows/system32"
  local backup_dir="$system32_dir/backup_dll"
  if ! [[ -d "$backup_dir" ]]; then
    mkdir "$backup_dir" || exit 1
  fi

  pushd "$tmp_cabextracted"
    wget "$download_url" 
    cabextract vc_redist.x64.exe || exit 1
    cabextract a10 || exit 1
    #cabextract a11 || exit 1
    local -a libs=( `find -type f -iname '*.dll' | sed -r 's/^\.\///' | sort -u | grep -E "$copy_filter_rx"` )

    for library in "${libs[@]}"; do
      chmod ugo+x "$library"
      mv --no-clobber "$system32_dir/$library" "$backup_dir" 2> /dev/null
      cp -f "$library" "$system32_dir"

      local alt_name="${library//_/-}"
      if [[ "$alt_name" != "$library" ]]; then
        ln -s -T "$system32_dir/$library" "$system32_dir/$alt_name"
      fi
    done
  popd
}

rename_game_data_dir_matching() {
  local dir_leaf="$1"
  local -a data_dirs=( `find "$GAME_ROOT" -type d -ipath "*/$1"` )

  for data_dir in "${data_dirs[@]}"; do
    local renamed_dir="${data_dir}.renamed"
    if ! [[ -d "$renamed_dir" ]]; then
      [[ -d "$data_dir" ]] || exit 1
      mv "$data_dir" "$renamed_dir"
    fi
  done
}

copy_user_settings() {
  local target_path="$PROTON_ROOT/user_settings.py"
  local backup_path="$PROTON_ROOT/user_settings.py.bak"
  [[ -f "$CURRENT_PROTON_SETTINGS" ]] || exit 1
  [[ -f "$target_path" ]] && mv "$target_path" "$backup_path"
  cp "$CURRENT_PROTON_SETTINGS" "$target_path"
}

