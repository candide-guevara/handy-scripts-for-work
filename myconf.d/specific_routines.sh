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
  my_assert -d $1 -a -d $2 || return 1
  local full_source="`readlink -f $1`"
  local base_source="`basename $full_source`"
  local date_str=`date +%y%m%d`
  local full_dest="`readlink -f $2`/${base_source}_${date_str}"
  local check_file="check_${base_source}_${date_str}.md5"
  local tmp_file="tmp_${base_source}_${date_str}.md5"
  local result_file="result_${base_source}_${date_str}.txt"

  my_assert -m "[ERROR] Invalid source ($full_source) or destination ($full_dest)" \
    -d "$full_source" -a ! -e "$full_dest" \
    || return 2

  pushd $full_source
  find -P . -type f -print0 | xargs -0 md5sum > $tmp_file
  grep -v "$tmp_file" $tmp_file > $check_file
  rm $tmp_file
  popd

  run_cmd cp -P -r -f $full_source $full_dest
  run_cmd rm $full_source/$check_file

  pushd $full_dest
  md5sum -c $check_file > $result_file
  my_assert -m "[ERROR] Bad copy $full_source -> $full_dest" "$?" '==' 0 \
    || return 3
  popd
}

## *USAGE: backup_home TARGET
## Copies home files into another directory and deletes uninteresting files
backup_home() {
  my_assert -d "$1" || return 1
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

## *USAGE : rotate_ssh_keys
## Rotates all keys found under $HOME/.ssh
rotate_ssh_keys() {
  [[ -d "$HOME/.ssh" ]] || return 1
  local nonce=`date '+%Y%m%d_%s'`
  local github_user='candide-guevara'
  read -s -p 'enter passphare for ssh keys' passphrase
  read -s -p 'enter llewelyn ip for exporting ssh keys' llewelyn_scp
  pushd "$HOME/.ssh"
  [[ -f authorized_keys ]] && rm authorized_keys
  [[ -z "$llewelyn_scp" ]] || llewelyn_scp="${USER}@${llewelyn_scp}"

  # BE CAREFUL IT IS A TRAP !
  # Any ssh keys created using a personal token are only valid as long as the token is not revoked
  # You cannot use temporal tokens to rotate keys
  #colecho $bldgrn "go to https://github.com/settings/tokens/new and create a token with admin privileges"
  #read -p 'token : ' access_token
  #local -a curl_opts=(
  #  --silent
  #  --tlsv1.2
  #  --header "Authorization: token $access_token"
  #)

  for pubkey in `find -type f -iname '*.pub'`; do
    echo -e "\n##### FOUND $pubkey #####\n"
    local pubkey="${pubkey#./}"
    local privkey="${pubkey%.pub}"
    mv "$pubkey" "${privkey}_${nonce}.pub.bk"
    mv "$privkey" "${privkey}_${nonce}.bk"
    run_cmd ssh-keygen -t rsa -b 4096 -f "$privkey" -C "${privkey}_${nonce}" -N "$passphrase"

    case "$privkey" in
    *arngrim*)
      cat "$pubkey" >> authorized_keys
      chmod og-wx authorized_keys
      [[ -z "$llewelyn_scp" ]] || scp -i "${privkey}_${nonce}.bk" authorized_keys "${llewelyn_scp}:.ssh"
    ;;

    *global_github*)
      colecho $txtgrn "go to https://github.com/settings/keys"
      echo "${privkey}_${nonce}"
      cat "$pubkey"
      read -r -s -n 1 -p 'done' ; echo
      #local data="{
      #  \"title\": \"${privkey}_${nonce}\",
      #  \"key\": \"`cat "$pubkey" | tr -d "\n"`\"
      #}"
      #curl "${curl_opts[@]}" https://api.github.com/users/"$github_user"/keys \
      #  | grep -E '^\s*.id.:\s+[[:digit:]]+,' \
      #  | sed -r 's/^\s*.id.:\s+([[:digit:]]+),/\1/' \
      #  | while read keyid; do
      #      run_cmd curl "${curl_opts[@]}" -X DELETE https://api.github.com/user/keys/"$keyid"
      #    done
      #run_cmd curl "${curl_opts[@]}" -X POST --data "$data" https://api.github.com/user/keys
      #run_cmd curl "${curl_opts[@]}" https://api.github.com/users/"$github_user"/keys
    ;;

    *repo_github*)
      local reponame="${privkey%_repo_github}"
      colecho $txtgrn "go to https://github.com/candide-guevara/browser_extensions/settings/keys"
      echo "${privkey}_${nonce}"
      cat "$pubkey"
      read -r -s -n 1 -p 'done' ; echo
      #local data="{
      #  \"title\": \"${privkey}_${nonce}\",
      #  \"key\": \"`cat "$pubkey" | tr -d "\n"`\",
      #  \"read_only\": false
      #}"
      #curl "${curl_opts[@]}" https://api.github.com/repos/"$github_user"/"$reponame"/keys \
      #  | grep -E '^\s*.id.:\s+[[:digit:]]+,' \
      #  | sed -r 's/^\s*.id.:\s+([[:digit:]]+),/\1/' \
      #  | while read keyid; do
      #      run_cmd curl "${curl_opts[@]}" -X DELETE https://api.github.com/repos/"$github_user"/"$reponame"/keys/"$keyid"
      #    done
      #run_cmd curl "${curl_opts[@]}" -X POST --data "$data" https://api.github.com/repos/"$github_user"/"$reponame"/keys
      #run_cmd curl "${curl_opts[@]}" https://api.github.com/repos/"$github_user"/"$reponame"/keys
    ;;
    esac

    [[ -z "$llewelyn_scp" ]] || scp "$privkey" "$pubkey" "${llewelyn_scp}:.ssh"
  done
  popd
  #access_token=bananas
  #colecho $txtylw "do not forget to delete the access token"
}

