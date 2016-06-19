## Defines some environment variables used in __my home machine__

# Some distributions do not add system binaries to normal users
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
export PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++')

export LESS='--clear-screen --LONG-PROMPT --ignore-case --RAW-CONTROL-CHARS'
export EDITOR=/usr/bin/vim
if [[ $LD_LIBRARY_PATH != */usr/local/lib* ]]; then
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
fi

#
# This variables contain default values for custom scripts
export MY_ROOT_SRC=$HOME/Programation
export MY_ROOT_CONF_DIR=$HOME/.myconf.d
export MY_ROOT_SCRIPT=$HOME/Scripts

# Awk script to include to get colors
export AWK_COLOR_SCRIPT="$MY_ROOT_SCRIPT/awk/colors.awk"

export PYTHONSTARTUP="$MY_ROOT_CONF_DIR/pythonrc.py"
# Common python modules look-up path
if [[ $PYTHONPATH != *$MY_ROOT_SCRIPT* ]]; then
  export PYTHONPATH="$PYTHONPATH:$MY_ROOT_SCRIPT"
fi

