#! /bin/bash
## Installs basic configuration scripts, ssh keys, vim color/syntax, terminal emulator ... in home

source ./install_base.sh

KV_TO_COPY=( 
  "configuration/shell_tools/gitignore:$HOME/.myconf.d"
  "configuration/shell_tools/hgignore:$HOME/.myconf.d"

  "configuration/shell_tools/gdb_common.py:$HOME/.myconf.d"
  "configuration/shell_tools/gdb_printers_filters.py:$HOME/.myconf.d"
  "configuration/shell_tools/gdb_prompt_and_help.py:$HOME/.myconf.d"

  "configuration/shell_tools/pythonrc.py:$HOME/.myconf.d"
  "configuration/kde4_conf/mysteam.desktop:$HOME/.local/share/applications"
)
DIRS_TO_COPY=(
  "myconf.d:$HOME/.myconf.d"
  "configuration/systemd_user:$HOME/.config/systemd/user"
)
FILES_TO_COPY=(
  "myconf.d/bashrc"

  "configuration/shell_tools/inputrc"
  "configuration/shell_tools/vimrc" 
  "configuration/shell_tools/gitconfig" 
  "configuration/shell_tools/gdbinit" 
  "configuration/shell_tools/hgrc"
)
DIRS_TO_WIPE=( "$HOME/.myconf.d" )

main_install "$@"
echo "ALL DONE !!"

