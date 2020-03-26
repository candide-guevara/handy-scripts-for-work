## Defines some environment variables used in __my home machine__

# Some distributions do not add system binaries to normal users
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
export PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++')

export LESS='--clear-screen --LONG-PROMPT --ignore-case --RAW-CONTROL-CHARS'
export EDITOR=/usr/bin/vim
if [[ $LD_LIBRARY_PATH != */usr/local/lib* ]]; then
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
fi

# This variables contain default values for custom scripts
candidates=(
 "$HOME"
 "$HOME/Programation"
 NOMORE
)
for candidate in "${candidates[@]}"; do
  [[ -d "$candidate" ]] \
    && export MY_ROOT_SRC="$candidate" \
    && break
  [[ "$candidate" == NOMORE ]] && echo "Cannot find MY_ROOT_SRC directory"
done

candidates=(
 "$HOME/handy-scripts-for-work"
 "$HOME/Programation/handy-scripts-for-work"
 "$HOME/Documents/handy-scripts-for-work"
 "`readlink -f .`"
 NOMORE
)
for candidate in "${candidates[@]}"; do
  [[ -d "$candidate" ]] \
    && [[ "$candidate" == *handy-scripts-for-work ]] \
    && export MY_HANDY_REPO_ROOT="$candidate" \
    && break
  [[ "$candidate" == NOMORE ]] && echo "Cannot find MY_HANDY_REPO_ROOT directory"
done

export MY_ROOT_CONF_DIR="$HOME/.myconf.d"
export MY_ROOT_SCRIPT="$MY_HANDY_REPO_ROOT/scripts"
export MY_ROOT_RCDIR="$MY_HANDY_REPO_ROOT/configuration/shell_tools"

# Awk script to include to get colors
export AWK_COLOR_SCRIPT="$MY_ROOT_SCRIPT/awk/colors.awk"

export PYTHONSTARTUP="$MY_ROOT_CONF_DIR/pythonrc.py"

