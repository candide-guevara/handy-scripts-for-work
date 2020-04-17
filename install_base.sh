#! /bin/bash
## Common routines used by installation scripts for home and work

run_cmd() {
  echo "Run : $@"
  "$@"
}

my_assert() {
  if test "$@"; then
    true
  else
    echo "[ERROR] 'test $@' is false"
    exit 1
  fi
}

test_is_windows() {
  osname=`uname -s | tr '[A-Z]' '[a-z]'`
  [[ $osname == cygwin* ]] && return 0
  [[ $osname == mingw* ]] && return 0
  [[ $osname == msys* ]] && return 0
  return 1
}

wipe_dirs() {
  for dir in "${DIRS_TO_WIPE[@]}"; do
    [[ -e "$dir" ]] && run_cmd rm -r "$dir"
    run_cmd mkdir -p "$dir"
  done
}

install_ssh() {
  local install_target="$HOME"
  local return_code=1
  #local install_target="/tmp"
  run_cmd cp "configuration/ssh.tar.gpg" "$install_target"

  pushd "$install_target"
  run_cmd gpg --decrypt --output ssh.tar ssh.tar.gpg \
    &&  run_cmd tar xf ssh.tar \
    &&  run_cmd shred -u ssh.tar ssh.tar.gpg \
    &&  return_code=0
  popd
  return "$return_code"
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
    my_assert -d "$src"
    [[ -f "$dest" ]] && run_cmd rm "$dest"
    [[ -d "$dest" ]] || run_cmd mkdir -p "$dest"
    # Note the trailing '/'
    # It is used to copy the contents of $src **directly** inside $dest if it exists
    # Example: coucou/*.txt -> salut/*.txt (NOT salut/coucou/*.txt)
    run_cmd rsync --links --one-file-system --recursive "$src/" "$dest"
  done

  for kv in "${KV_TO_COPY[@]}"; do
    local src="${kv%%:*}"
    local dest="${kv#*:}"
    my_assert -f "$src"
    run_cmd cp --no-dereference --one-file-system "$src" "$dest"
  done

  for file in "${FILES_TO_COPY[@]}"; do
    my_assert -f "$file"
    run_cmd cp --no-dereference --one-file-system --no-target-directory "$file" "$HOME/.`basename $file`"
  done

  # reload systemd units if they changed
  systemctl --user daemon-reload
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
      i) wipe_dirs && install_files && install_vim ;;
      s) wipe_dirs && install_ssh ;;
      d) diff_files ;;
      \?) echo -e " USAGE: install.sh 
          -i    install bash profile scripts
          -s    install ssh keys
          -d    difference between installed and latest bash scripts
         " ;;
    esac
  done
}

