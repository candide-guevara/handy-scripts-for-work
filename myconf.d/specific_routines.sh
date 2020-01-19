## Simple specific (home or work) routines to shortcut common tasks

alias blkid="sudo blkid"
alias jls="sudo journalctl"
alias cgls="sudo systemd-cgls"
alias sc="sudo systemctl"

## *USAGE: start_sshd
## Starts the sshd daemon (using systemd)
start_sshd() {
  start_cmd=( sudo systemctl start sshd.service )
  check_cmd=( sudo systemctl status sshd.service )
  run_cmd ${start_cmd[@]}
  run_cmd ${check_cmd[@]}
}

## *USAGE: mysteam
## Launches steam inside a systemd unit to contain all of its sneaky child processes
mysteam() {
  local name=mysteam
  if systemctl --user is-active --quiet "$name"; then
    systemctl --user stop "$name"
  else
    systemctl --user start "$name"
    colecho $txtcyn "Stop steam by running '${FUNCNAME[0]}' again"
  fi
}

## *USAGE: pdf_shrink DOCS
## Transforms pdf to a lower quality to share over email.
pdf_shrink() {
  for name in "$@"; do
    local new_name="__`basename "$name"`"
    run_cmd gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH \
      -sOutputFile="$new_name" "$name"
  done
}

## *USAGE: backup_cp SOURCE TARGET
## Copies SOURCE into TARGET/SOURCE_date, calculates and checks md5 sums
backup_cp() {
  my_assert -d $1 -a -d $2
  local full_source="`readlink -f $1`"
  local base_source="`basename $full_source`"
  local date_str=`date +%y%m%d`
  local full_dest="`readlink -f $2`/${base_source}_${date_str}"
  local check_file="check_${base_source}_${date_str}.md5"
  local tmp_file="tmp_${base_source}_${date_str}.md5"
  local result_file="result_${base_source}_${date_str}.txt"

  my_assert -m "[ERROR] Invalid source ($full_source) or destination ($full_dest)" \
    -d "$full_source" -a ! -e "$full_dest" 

  pushd $full_source
  find -P . -type f -print0 | xargs -0 md5sum > $tmp_file
  grep -v "$tmp_file" $tmp_file > $check_file
  rm $tmp_file
  popd

  run_cmd cp -P -r -f $full_source $full_dest
  run_cmd rm $full_source/$check_file

  pushd $full_dest
  md5sum -c $check_file > $result_file
  my_assert -m "[ERROR] Bad copy $full_source -> $full_dest" "$?" '==' 0
  popd
}

## *USAGE: backup_home TARGET
## Copies home files into another directory and deletes uninteresting files
backup_home() {
  my_assert -d "$1"
  pushd "$1"
  run_cmd cp -TrxPu "$HOME" ./ || return 1
  run_cmd rm -r .cache .thumbnails
  run_cmd rm -r .nuget .dotnet .templateengine .vscode/extensions
  run_cmd rm -r .mono .gem .gnupg .jak .mozilla 
  run_cmd rm -r .config/google-chrome .config/chromium .config/Code
  run_cmd mkdir .config/__retroarch .__spring
  run_cmd cp -r .config/retroarch/retroarch.cfg .config/retroarch/config .config/__retroarch
  run_cmd cp -r .spring/springsettings.cfg .__spring
  run_cmd rm -r .config/retroarch .spring
  run_cmd rm -r RetroArch Scripts
  run_cmd rm -r .local/share/baloo .local/share/akonadi
  run_cmd rm -r ./.aws/shell/cache/ ./.aws/shell/*completions.json.docs
  run_cmd rm -r ./.kde/share/apps/ktorrent ./.kde/share/apps/amarok/mysqle ./.kde/share/apps/amarok/albumcovers

  run_cmd du -chPxd 1
  popd
}

