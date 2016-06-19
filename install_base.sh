#! /bin/bash
## Common routines used by installation scripts for home and work

run_cmd() {
  echo "Run : $@"
  "$@"
}

test_is_windows() {
  osname=`uname -s | tr '[A-Z]' '[a-z]'`
  [[ $osname == cygwin* ]] && return 0
  [[ $osname == mingw* ]] && return 0
  [[ $osname == msys* ]] && return 0
  return 1
}

create_dirs() {
  for dir in "${DIRS_TO_CREATE[@]}"; do
    [[ -e "$dir" ]] || run_cmd mkdir -p "$dir"
  done
}

install_ssh() {
  run_cmd cp "$SSH_PATH" "$HOME/ssh.tar.gpg"

  pushd "$HOME"
  run_cmd gpg ssh.tar.gpg
  run_cmd tar xf ssh.tar
  run_cmd rm --recursive ssh.tar ssh.tar.gpg
  popd
}

install_vim() {
  test_is_windows || return
  run_cmd cp "$VIM_PLUGINS" "$HOME/vim.tar.gz"

  pushd "$HOME"
  run_cmd tar zxf vim.tar.gz
  run_cmd rm --recursive vim.tar.gz
  run_cmd cp --recursive .vim vimfiles
  run_cmd cp --no-target-directory .vimrc _vimrc
  popd
}

install_files() {
  for kv in "${DIRS_TO_COPY[@]}"; do
    local src="${kv%%:*}"
    local dest="${kv#*:}"
    [[ -d "$src" ]] || exit 1
    [[ -d "$dest" ]] && run_cmd rm -r "$dest"
    run_cmd cp --no-dereference --one-file-system --recursive "$src" "$dest"
  done

  for kv in "${KV_TO_COPY[@]}"; do
    local src="${kv%%:*}"
    local dest="${kv#*:}"
    [[ -f "$src" ]] || exit 1
    run_cmd cp --no-dereference --one-file-system "$src" "$dest"
  done

  for file in "${FILES_TO_COPY[@]}"; do
    [[ -f "$file" ]] || exit 1
    run_cmd cp --no-dereference --one-file-system --no-target-directory "$file" "$HOME/.`basename $file`"
  done
}

diff_files() {
  local -A done_files

  for kv in "${DIRS_TO_COPY[@]}"; do
    local src="${kv%%:*}"
    local dest="${kv#*:}"
    pushd "$src"
    for file in *; do
      run_cmd diff -u "$file" "$dest/$file"
      echo -e "------------------------------------------------------------\n"
      done_files+=( ["$dest/$file"]="1" )
    done
    popd
  done

  for kv in "${KV_TO_COPY[@]}"; do
    local src="${kv%%:*}"
    local dest="${kv#*:}"
    [[ -d "$dest" ]] && dest="$dest/`basename $src`"
    [[ "${done_files[$dest]}" == 1 ]] && continue
    run_cmd diff -u "$src" "$dest"
    echo -e "------------------------------------------------------------\n"
    done_files+=( ["$dest"]="1" )
  done

  for file in "${FILES_TO_COPY[@]}"; do
    local dest="$HOME/.`basename $file`"
    [[ "${done_files[$dest]}" == 1 ]] && continue
    run_cmd diff -u $file "$dest"
    echo -e "------------------------------------------------------------\n"
    done_files+=( ["$dest"]="1" )
  done
}

main_install() {
  while getopts 'ivscd' opt; do
    case $opt in
      i) create_dirs && install_files && install_vim ;;
      s) create_dirs && install_ssh ;;
      d) diff_files ;;
      \?) echo -e " USAGE: install.sh 
          -i    install bash profile scripts
          -s    install ssh keys
          -d    difference between installed and latest bash scripts
         " ;;
    esac
  done
}

