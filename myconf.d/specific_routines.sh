## Simple specific (home or work) routines to shortcut common tasks

alias blkid="sudo blkid"
alias jls="sudo journalctl"
alias cgls="sudo systemd-cgls"
alias sc="sudo systemctl"
JELANDA_HOSTNAME=cguev

## *USAGE: git_check_all_pushed
## Finds all git repos under the current directory and checks all local modifications have been pushed.
git_check_all_pushed() {
  local -a repo_roots=( `find . -type d -name '.git' | xargs dirname` )
  ssh_agent_load_key "global_github"

  for repo in "${repo_roots[@]}"; do
  pushd "$repo" &> /dev/null
    colecho $txtcyn "CHECKING '${repo}'"
    IFS=$'\n' local -a modified_tracked=( `git status --porcelain --untracked-files=no` )
    if [[ "${#modified_tracked[@]}" -gt 0 ]]; then
      colecho $txtylw "[WARN] '$repo' has modification to tracked files"
      printf "  %s\n" "${modified_tracked[@]}"
    fi
    if ! git remote --verbose | grep 'git@github.com' > /dev/null; then
      colecho $txtylw "[WARN] '$repo' does not have a github remote"
      popd &> /dev/null
      continue
    fi
    if ! git fetch --all > /dev/null; then
      errecho "Failed to fetch branches for '$repo'"
      popd &> /dev/null
      return 1
    fi
    local -a remote_branches=( `git branch --remote | sed -r 's/^[ *]*([^ ]+).*/\1/'` )
    for branch in "${remote_branches[@]}"; do
      local local_branch="`basename "$branch"`"
      if ! git branch | grep -E " $local_branch\$" > /dev/null; then
        errecho "In '$repo' remote branch '$branch' does not match any local branch (expected '$local_branch')"
        popd &> /dev/null
        return 1
      fi
      #for rev_range in "${local_branch}..${branch}" "${branch}..${local_branch}"; do
      for rev_range in "${branch}..${local_branch}"; do
        IFS=$'\n' local -a missing_changes=( `git log --pretty=oneline "$rev_range"` )
        if [[ "${#missing_changes[@]}" -gt 0 ]]; then
          colecho $txtylw "[WARN] '${repo}:${branch}' '$rev_range' misses changes :"
          printf "  %s\n" "${missing_changes[@]}"
        fi
      done
    done
  popd &> /dev/null
  done
  colecho $txtcyn "DONE ${#repo_roots[@]} checked"
}

## *USAGE: gdrive_file_download LAST_DAYS
## Downloads all files created in the LAST_DAYS under a given google drive folder.
## OAuth inspiration from https://gist.github.com/LindaLawton/cff75182aac5fa42930a09f58b63a309#file-googleauthenticationcurl-sh
gdrive_file_download() {
  # API console : https://console.developers.google.com/apis/credentials?project=api-project-603840956042
  local days_thres="${1:-365}"
  local client_id="$2"
  local client_secret="$3"
  local folder_id="$4"

  local discovery_doc="`mktemp`"
  local token_response="`mktemp`"
  local passphrase="`dd if=/dev/random bs=64 count=1 | base64`"

  local discover_auth_url="https://accounts.google.com/.well-known/openid-configuration"
  run_cmd curl --silent "$discover_auth_url" > "$discovery_doc" \
    || errecho "Could not get discovery_doc"
  local auth_endpt_url="`grep '"authorization_endpoint"' "$discovery_doc" | sed -r 's/.*"([^"]+)",?$/\1/'`"
  local token_endpt_url="`grep '"token_endpoint"'        "$discovery_doc" | sed -r 's/.*"([^"]+)",?$/\1/'`"
  local drive_v3_url='https://www.googleapis.com/drive/v3/files'

  local drive_read_scope="https://www.googleapis.com/auth/drive.readonly"
  # This value indicates that Google's authorization server should return the authorization code in the browser's title bar
  local redirection_url="urn:ietf:wg:oauth:2.0:oob"
  local code_fetch_url="${auth_endpt_url}?client_id=${client_id}&redirect_uri=${redirection_url}&scope=${drive_read_scope}&response_type=code"
  local oauth_code=""

  read -p "go to '$code_fetch_url' and paste code : " oauth_code

  curl --silent \
    --data-urlencode "code=${oauth_code}" \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "client_secret=${client_secret}" \
    --data-urlencode "redirect_uri=${redirection_url}" \
    --data-urlencode "grant_type=authorization_code" \
    "$token_endpt_url" \
    | gpg --batch --symmetric --passphrase "$passphrase" \
    > "$token_response" \
    || errecho "Could not get token from '$token_endpt_url'"
  oauth_code=""

  #{
  #  "access_token": "ya29.a0Ae-IDNNv7n-slj",
  #  "expires_in": 3599,
  #  "refresh_token": "1//03VFvcnVfJKRdC-L9I-VkLgy-JErsdf",
  #  "scope": "https://www.googleapis.com/auth/drive.readonly",
  #  "token_type": "Bearer"
  #}
  local access_token="`gpg --batch --passphrase "$passphrase" --decrypt "$token_response" | grep '"access_token"' | sed -r 's/.*"([^"]+)",?$/\1/'`"

  #{
  #  "kind": "drive#file",
  #  "id": "1D-rM9-fvf",
  #  "name": "filenamedummy",
  #  "mimeType": "image/png"
  #},
  local list_response="`mktemp`"
  local time_thres_utc="`date --utc --date="$days_thres days ago" '+%Y-%m-%dT%H:%M:%S'`"
  local pageToken=""
  colecho $txtcyn "listing files from folder since '$time_thres_utc'"
  while true; do
    local one_response="`mktemp`"
    echo "Listing files pageToken='$pageToken'"
    curl --silent --get \
      --header "Authorization: Bearer $access_token" \
      --data-urlencode "q=('$folder_id' in parents) and (modifiedTime > '$time_thres_utc')" \
      --data-urlencode "orderBy=name" \
      --data-urlencode "pageToken=$pageToken" \
      "$drive_v3_url" \
      | tee --append "$list_response" \
      > "$one_response" \
      || errecho "Could not get folder listing from '$drive_v3_url'"

      pageToken="`grep '"nextPageToken"' "$one_response" | sed -r 's/.*"([^"]+)",?$/\1/'`"
      [[ -z "$pageToken" ]] && break
      sleep 1
  done

  local ids_file="`mktemp`"
  local names_file="`mktemp`"
  grep '"id"' "$list_response" | sed -r 's/.*"([^"]+)",?$/\1/' \
    > "$ids_file" \
    || errecho "No file ids found in '$list_response'"
  grep '"name"' "$list_response" | sed -r 's/.*"([^"]+)",?$/\1/' \
    > "$names_file" \
    || errecho "No file names found in '$list_response'"

  colecho $txtcyn "Downloading `wc -l "$ids_file"` files"
  while read fileid <&3 && read filename <&4; do
    echo "Downloading '$filename'='$fileid'"
    curl --silent --get \
      --header "Authorization: Bearer $access_token" \
      --data-urlencode "alt=media" \
      "$drive_v3_url/$fileid" \
      > "$filename" \
      || errecho "Could not download '$filename'='$fileid'"
    sleep 1
  done 3< "$ids_file" 4< "$names_file"
}

## *USAGE: start_sshd
## Starts the sshd daemon (using systemd)
start_sshd() {
  start_cmd=( sudo systemctl start sshd.service )
  check_cmd=( sudo systemctl status sshd.service )
  run_cmd ${start_cmd[@]}
  run_cmd ${check_cmd[@]}
}

## *USAGE: import_pics_from_jelanda IP [DAY_OFFSET]
## Gets all scanned docs via scp from jelanda host.
import_pics_from_jelanda() {
  ssh_agent_load_key "arngrim_id_rsa"

  local jelanda_ip="$1"
  local day_offset="$2"
  [[ -z "$jelanda_ip" ]] && read -s -p 'enter jelanda ip' jelanda_ip
  local jelanda_host="${JELANDA_HOSTNAME}@${jelanda_ip}"
  local docs_dir="Documents"
  local -a dates=( `date +"%Y%m%d"` )
  [[ ! -z "$day_offset" ]] && dates=( `date +"%Y%m%d" --date="$day_offset days ago"` )
  local -a indexes=( `seq --format="%04.0f" 1 20` )
  local all_remote_imgs="`mktemp`"

  ssh "${jelanda_host}" dir "$docs_dir" | grep IMG > "$all_remote_imgs"
  for date_str in "${dates[@]}"; do
  for index in "${indexes[@]}"; do
    local filename="IMG_${date_str}_${index}.pdf"
    grep "$filename" "$all_remote_imgs" \
      && run_cmd scp "${jelanda_host}:${docs_dir}/$filename" .
  done
  done
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
    # To raster (version is always 1.3 ?!), use 'pdfimage8' for grayscale
    # https://www.ghostscript.com/doc/current/Use.htm#Invoking
    # gs -sDEVICE=pdfimage32 -dCompatibilityLevel=1.4 \
    #   -r300 -dGraphicsAlphaBits=4 -dTextAlphaBits=4 \
    #   -dNOPAUSE -dQUIET -dBATCH -dSAFER

    # To transform to grayscale add
    # https://ghostscript.com/doc/9.20/VectorDevices.htm#PDFWRITE
    #-sColorConversionStrategy=Gray -dProcessColorModel=/DeviceGray \
    run_cmd gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
      -dNumRenderingThreads=`nproc` \
      -dSAFER -dNOPAUSE -dQUIET -dBATCH \
      -sOutputFile="$new_name" "$name"
    # Some perf options (do not make much difference)
    #-dMaxPatternBitmap=$((64 * 1024 * 1024)) -dMaxBitmap=$((64 * 1024 * 1024)) -dBufferSpace=$((1024 * 1024 * 1024)) \
    # Looks like BS this only makes gs crash
    #-c $((1024 * 1024 * 1024)) setvmthreshold -f \
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

## *USAGE: ssh_agent_load_key [KEY_NAME]
## Starts the ssh-agent if not started already and loads KEY_NAME.
ssh_agent_load_key() {
  local keyname="$1"
  if pgrep ssh-agent; then
    echo "ssh-agent already started"
  else
    local ssh_agent_cfg="`mktemp`"
    ssh-agent > "$ssh_agent_cfg"
    run_cmd source "$ssh_agent_cfg"
    run_cmd ssh-add "$HOME/.ssh/$keyname"
  fi
}

## *USAGE : rotate_ssh_keys
## Rotates all keys found under $HOME/.ssh
rotate_ssh_keys() {
  [[ -d "$HOME/.ssh" ]] || return 1
  local nonce=`date '+%Y%m%d_%s'`
  local github_user='candide-guevara'
  read -s -p 'enter passphrase for ssh keys' passphrase
  read -s -p 'enter llewelyn ip for exporting ssh keys' llewelyn_scp
  read -s -p 'enter jelanda ip for exporting ssh keys' jelanda_ip
  pushd "$HOME/.ssh"
  [[ -f authorized_keys ]] && rm authorized_keys
  [[ -z "$llewelyn_scp" ]] || llewelyn_scp="${USER}@${llewelyn_scp}"
  [[ -z "$jelanda_ip" ]] || jelanda_scp="${JELANDA_HOSTNAME}@${jelanda_ip}"

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
      if ! [[ -z "$jelanda_scp" ]]; then
        cp authorized_keys authorized_keys_win
        unix2dos authorized_keys_win
        scp -i "${privkey}_${nonce}.bk" authorized_keys_win "${jelanda_scp}:.ssh"
        local -a win_ssh_ps=( ssh -i "${privkey}_${nonce}.bk" "$jelanda_scp" powershell /C )
        # https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH
        # the authorized_keys file should have the following access rights
        # NT AUTHORITY\SYSTEM:(F)
        # BUILTIN\Administrators:(F)
        # JELANDA\cguev:(F)
        "${win_ssh_ps[@]}" 'icacls    .ssh\authorized_keys_win .ssh\authorized_keys'
        "${win_ssh_ps[@]}" 'mv -Force .ssh\authorized_keys_win .ssh\authorized_keys'
        rm authorized_keys_win
      fi
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

