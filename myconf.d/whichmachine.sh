#! /bin/bash
## This shell script sets some variables depending on the machine (typically IS_*).
## It will also set the right command if there is a difference between shells.

shell_version="`$SHELL --version | head -n 1`"
if [[ $SHELL == *bash* ]] || [[ "$shell_version" == *bash* ]]; then
  export IS_BASH=1
elif [[ $SHELL == *zsh* ]] || [[ "$shell_version" == *zsh* ]]; then
  export IS_ZSH=1
else
  echo "[ERROR] COULD NOT DETERMINE SHELL !!"
fi

## *USAGE : test_is_windows
## Returns 0 if running on windows, 1 otherwise
test_is_windows() {
  osname=`uname -s | tr '[A-Z]' '[a-z]'`
  [[ $osname == cygwin* ]] && return 0
  if [[ $osname == mingw* ]] || [[ $osname == msys* ]]; then 
    export IS_MSYS=1
    return 0
  fi
  return 1
}

## *USAGE : is_mac
## Returns 0 if running on mac os, 1 otherwise
test_is_mac() {
  osname=`uname -s | tr '[A-Z]' '[a-z]'`
  [[ $osname == darwin* ]] && return 0
  return 1
}

## *USAGE : is_unix
## Returns 0 if running on Unix, 1 otherwise
test_is_unix() {
  osname=`uname -s | tr '[A-Z]' '[a-z]'`
  [[ $osname == sun* ]] && return 0
  [[ $osname == aix* ]] && return 0
  [[ $osname == linux* ]] && return 0
  return 1
}

## *USAGE : test_is_linux
## Returns 0 if running on Linux, 1 otherwise
test_is_linux() {
  osname=`uname -s | tr '[A-Z]' '[a-z]'`
  [[ $osname == linux* ]] && return 0
  return 1
}

## *USAGE : export_win_temp_dir
## Sets the environment variables pointing to the temporary directory
export_win_temp_dir() {
  local drive=""
  local temp_dir=""

  [[ -d /d ]] && drive=d
  [[ -d /c ]] && drive=c
  [[ -d /e ]] && drive=f
  [[ -d /f ]] && drive=e
  [[ -d "/$drive/tmp" ]] &&  temp_dir="/$drive/tmp"
  [[ -d "/$drive/temp" ]] && temp_dir="/$drive/temp"

  if [[ ! -d "$temp_dir" ]]; then
    temp_dir="/$drive/temp"
    echo "[WARN] Creating temp dir @ '$temp_dir' !!"
    mkdir "$temp_dir"
  fi
  export TEMP="$temp_dir"
  export TMP="$temp_dir"
}

## *USAGE : export_nix_temp_dir
## Sets the environment variables pointing to the temporary directory
export_nix_temp_dir() {
  if [[ -z "$TEMP" ]]; then
    if ! [[ -z "$TMP" ]]; then
      export TEMP="$TMP"
    else
      export TEMP=/tmp
    fi
  fi
  [[ -z "$TMP" ]] && export TMP="$TEMP"
}

# Here we determine in which kind of machine we are
machinename=`hostname`

# desktop, laptop, windows_vm, surface, emergency_boot
if [[ $machinename == arngrim* ]] || [[ $machinename == llewelyn* ]] || [[ $machinename == badrach* ]] || [[ $machinename == jelanda* ]] || [[ $machinename == lawfer* ]]; then
  export IS_HOME=1
elif [[ $machinename == penguin* ]]; then
  export IS_WORK=1
else
  echo "[ERROR] Cannot find the machine type !!!"
fi

if test_is_windows; then
  export IS_WINDOWS=1
  export_win_temp_dir
elif test_is_linux; then
  export IS_LINUX=1
  export IS_UNIX=1
  export_nix_temp_dir
elif test_is_unix; then
  export IS_UNIX=1
  export_nix_temp_dir
else 
  echo "[ERROR] COULD NOT DETERMINE OS TYPE !!"
fi

if [[ $IS_BASH == 1 ]]; then
  export SH_READ='read -e'
elif [[ $IS_ZSH == 1 ]]; then
  export SH_READ='vared'
fi

