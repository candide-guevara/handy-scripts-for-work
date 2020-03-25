#! /bin/bash
## Defines command alias and routines for tasks common to home and work

AWK_MAN_FORMAT="$MY_ROOT_SCRIPT/awk/manparser.awk"
TMP_HELP_FILE="$TEMP/help.autogenerated.tmp"

## *USAGE : mll [PATTERN] [EXTRA_FLAG]
## Like ls with long listing but PATTERN is case insensitive and
## matches any part of the file name
mll() {
  setoption nocaseglob
  [[ -z $pattern ]] || shift
  # Zsh does not perform file name expansion on variables and local forces expansion
  eval "ls $1 $pattern"
  setoption caseglob
}

# Some scripts in the office may break unless we do this
alias ls='ls --color=always -C'
if [[ "$IS_BLOOM_MAC" == 1 ]]; then
  alias ls='ls -GC'
  alias ll='ls -lhG'
elif [[ ("$IS_HOME" == 1 && "$IS_BASH" == 1) || "$IS_MSYS" == 1 ]]; then
  alias ll='ls -l --group-directories-first --human-readable --time-style=iso --no-group'
elif [[ "$IS_BLOOM_UNIX" == 1 || "$IS_UNIX" == 1 ]]; then
  alias ll='ls -l --color=always --human-readable --time-style=iso --no-group'
elif [[ -z $IS_BLOOM_BNX_NODE ]]; then
  alias ll='ls -l --color=always --human-readable --no-group'
else
  alias ll='ls -lh'
fi

alias vi=vim
alias su='su --login'

alias lll='ll | less'
alias la='ll -A'
alias lla='ll -A | less'

alias mps='ps -ef | grep -i'
alias menv='env | sort | grep -i'

alias ..='cd ..; ls'
alias .2='cd ..; cd ..; ls'
alias .3='cd ..; cd ..; cd ..; ls'

## *USAGE : mll [PATTERN] [EXTRA_FLAG]
## Like ls with long listing but PATTERN is case insensitive and
## matches any part of the file name
mll() {
  [[ $IS_BASH == 1 && $IS_HOME == 1 ]] && local option="--group-directories-first"
  [[ ! -z $1 && $1 != -* ]] && local pattern="*$1*" 
  local ls_command
  ls_command=( ls "-l" "--color=always" "--human-readable" "--time-style=iso" "--no-group" $option )

  setoption nocaseglob
  [[ -z $pattern ]] || shift
  # Zsh does not perform file name expansion on variables and local forces expansion
  eval "${ls_command[*]} $1 $pattern"
  setoption caseglob
}

## *USAGE : mfind SEARCH_PATTERN [ROOT_DIR]
## Does NOT follow symlinks. If ROOT_DIR is not specified, the current dir will be used
mfind() {
  colecho $bldylw "Errors are redirected to /dev/null"
  if [[ $IS_BLOOM_MAC == 1 ]]; then
    find . -iname "*$1*" 2> /dev/null
  elif [[ "$IS_UNIX" == 1 || "$IS_MSYS" == 1 ]]; then
    find -P $2 -maxdepth 9 -iname "*$1*" 2> /dev/null
  else
    find $2 -maxdepth 9 -iname "*$1*" 2> /dev/null
  fi  
}

## *USAGE : rgrep [GREP_OPTIONS] SEARCH_REGEX
## Searches recursevely for SEARCH_REGEX in the current directory. Does not support recursive option
function rgrep() {
  colecho $bldylw "Errors are redirected to /dev/null"
  grep_cmd=( grep --recursive --with-filename --line-number --binary-files=without-match --extended-regexp --ignore-case )
  if [[ "$IS_BLOOM_MAC" == 1 || "$IS_UNIX" == 1 || "$IS_MSYS" == 1 ]]; then
    grep_cmd=( "${grep_cmd[@]}" --color=always )
  fi
  ${grep_cmd[@]} "$@" * 2> /dev/null
}

###############################################################################################
## *USAGE : mgrep SEARCH_REGEX FILES_TO_SCAN
## Searches for SEARCH_REGEX in FILES_TO_SCAN or ALL files in current directory
mgrep() {
  colecho $bldylw "Errors are redirected to /dev/null"
  local pattern="$1"
  shift

  # zgrep for sun machines is not good !
  if [[ "$IS_BLOOM_MAC" == 1 || "$IS_UNIX" == 1 || "$IS_MSYS" == 1 ]]; then
    grep_cmd=( zgrep --color=always --line-number --binary-files=without-match --extended-regexp --ignore-case )
  else
    grep_cmd=( grep --line-number --binary-files=without-match --extended-regexp --ignore-case )
  fi

  if [[ ${#@} == 0 ]]; then
    ${grep_cmd[@]} "$pattern" 2> /dev/null
  else
    ${grep_cmd[@]} "$pattern" "$@" 2> /dev/null
  fi
}

## *USAGE : cat_burst FILES
## Outputs FILES to stdout along with their names
cat_burst() {
  for file in "$@"; do
    if [[ -f $file ]]; then
      colecho $bldcyn "\n++++++ $file +++++++"
      cat "$file"
    else
      colecho $bldylw "$file is not a file"
    fi
  done
}

## *USAGE : is_subdirectory ROOT_DIR CHILD_DIR
## Return 0 if CHILD_DIR is contained in ROOT_DIR, 1 otherwise
is_subdirectory() {
  local root="`echo $1 | tr '[:upper:]' '[:lower:]'`"
  local child="`echo $2 | tr '[:upper:]' '[:lower:]'`"
  [[ "$child" == "$root"* ]] && return 0
  return 1
}

## *USAGE: run_cmd [-n OUTFILE_PREFIX][-l][-r HOSTNAME] CMD [ARGUMENTS]
## Prints and runs CMD [ARGUMENTS]
## -n option will run CMD with nohup and redirect outputs to OUTFILE_PREFIX
## -l option will pipe stdout to less
## -r option will execute remotely on HOSTNAME
run_cmd() {
  local OPTIND 
  while getopts ':n:r:l' opt; do
    case $opt in
      n) 
        shift ; shift
        local out_file="${OPTARG}_`date +%y%m%d-%H%M%S`"
        colecho $txtcyn "Running: $@" >&2
        nohup "$@" > "${out_file}.stdout" 2> "${out_file}.stderr" &
        return $?
      ;;
      r) 
        shift ; shift
        colecho $txtcyn "Running: $@" >&2
        __run_rem__ "$OPTARG" "$@"
        return $?
      ;;  
      l) 
        shift
        colecho $txtcyn "Running: $@" >&2
        "$@" | less
        return 0
      ;;  
    esac
  done
  shift $((OPTIND-1))

  colecho $txtcyn "Running: $@" >&2
  "$@"
  return $?
}

## *USAGE: my_assert [-m MESSAGE] PREDICATE
## Asserts predicate or die and print MESSAGE
my_assert() {
  local message=''
  if [[ x$1 == x-m ]]; then
    message=$2
    shift ; shift
  fi
  test "$@"
  if [[ $? != 0 ]]; then
    errecho "[ASSERT FAIL] $@"
    [[ -z $message ]] || echo " => $message"
    exit 1
  fi
}

## *USAGE: conf_source [-e]
## Re sources the bash customization scripts. -e allows to edit the files before sourcing.
conf_source() {
  unset BASHPROFILE_ALREADY_SOURCED
  pushd "$MY_ROOT_SRC/handy-scripts-for-work"
  my_assert -f install.sh
  bash ./install.sh -i
  popd
  my_assert -d $MY_ROOT_CONF_DIR
  [[ -z $1 ]] || vim -p $MY_ROOT_CONF_DIR/*.sh
  my_assert -e $HOME/.bashrc
  source $HOME/.bashrc
}

## *USAGE : insert_bytes FILE OFFSET BYTES
## Inserts bytes into file at OFFSET. BYTES is a string of escape hex numbers (ex '\x0a\xdd')
insert_bytes() {
  local out_file=$1
  copy_byte_cmd=( dd conv=notrunc bs=1 seek=$2 of=$out_file )

  colecho $txtcyn "Inserting bytes using : ${copy_byte_cmd[*]}"
  printf "$3" | ${copy_byte_cmd[@]}
  hexdump -C $out_file
}

## *USAGE : get_cat
## Determines the right cat command to use if the file is compressed or not
get_cat() {
  local is_gzipped=`file $1 | grep --count --ignore-case "gzip"`
  CAT_COMMAND=cat
  [[ $is_gzipped == 1 ]] && CAT_COMMAND=zcat
}

## *USAGE : change_strings PATTERN_TO_REPLACE REPLACEMENT
## Changes any parts of the file matching PATTERN_TO_REPLACE with REPLACEMENT
change_strings() {
    local pattern="${1:-XXXXXXXXX}"
    local change="${2}"
    echo "Touching files `grep -rIEl "$pattern" *`"

    grep -rIElZ "$pattern" * 2> /dev/null | \
      grep -Zzv ".svn"                    | \
      xargs -r0 sed -r "s/$pattern/$change/g" | less

    pattern=`echo "$pattern" | sed -r 's/\\\/\\\\\\\\/g'`
    change=`echo "$change"   | sed -r 's/\\\/\\\\\\\\/g'`
    local final_cmd=( grep -rIElZ "'$pattern'" "*" "2>" /dev/null "|" grep -Zzv "'.svn'" "|" xargs -r0 sed -ri "'s/$pattern/$change/g'" )

    echo "Do it for real :"
    colecho $bldgrn "${final_cmd[@]}"
    history -s "${final_cmd[@]}"
}

## *USAGE : delete_all_dirs [-f] PATTERN_TO_DELETE 
## Deletes all items (directories by default) which match PATTERN_TO_DELETE. Be careful !
delete_all_dirs() {
  local item_type=d
  if [[ $1 == '-f' ]]; then
    item_type=f
    shift
  fi
  local pattern=${1:-XXXXXXXXX}
  
  echo -e "You will delete files :\n`find -type $item_type -iname \"$pattern\"`"
  #find -type $item_type -iname "$pattern" -print0 2> /dev/null | xargs -r0 rm -fr
  echo "Do it for real :"
  colecho $bldgrn "  find -type $item_type -iname \"$pattern\" -print0 2> /dev/null | xargs -r0 rm -fr"
}

## *USAGE : vim_crypt CRYPT_FILE
## Decrypts CRYPT_FILE edits it with vim and crypts it again
vim_crypt() {
  local crypt_file="$1"
  local gpg_pwd=""
  # For extra security better create this in a memory backed filesystem
  local user_num=`id -u`
  local tmp_dir=`mktemp -d -p "/run/user/$user_num"`
  local tmp_file=`mktemp -u -p "$tmp_dir"`

  chmod 'go-rwx' "$tmp_dir"
  read -s -p "passphrase : " gpg_pwd

  function __cleanup__() {
    local -a msg=( "delete" "$tmp_dir"/.ssh "$tmp_dir"/* " [y/N] : ")
    local doit=n
    read -p "${msg[*]}" doit
    [[ "$doit" == "y" ]] || return 3
    rm -rf "$tmp_dir"
  }

  local -a vim_cmd=( vim -c ":file $tmp_file" -c ':set nobackup' -c ':set nowritebackup' -c ':set noswapfile' )
  local -a crypt_cmd=( gpg --symmetric --cipher-algo AES256 --passphrase "$gpg_pwd" --output '-' )
  local -a decrypt_cmd=( gpg --decrypt --passphrase "$gpg_pwd" )

  (
    trap __cleanup__ EXIT INT TERM
    if [[ -e "$crypt_file" ]]; then
      "${decrypt_cmd[@]}" "$crypt_file" | "${vim_cmd[@]}" -
      [[ "${PIPESTATUS[0]}" == "0" ]] && [[ -f "$tmp_file" ]] \
        && "${crypt_cmd[@]}" "$tmp_file" > "$crypt_file"
    fi  
  )
}

## *USAGE : mydiff [FILE1 FILE2]
## Diffs 2 files or stdin and pipes it to vim
mydiff() {
  local filter=cat
  [[ -z "$IS_WINDOWS" ]] || filter=dos2unix
  which "$filter" 2> /dev/null || return 1
  if [[ $# == 0 ]]; then
    "$filter" | vim -R -c "set syntax=diff" -
  else
    diff -u --ignore-all-space "$@" | "$filter" | vim -R -c "set syntax=diff" -
  fi  
}

## *USAGE : rotate_ssh_keys
## Rotates all keys found under $HOME/.ssh
rotate_ssh_keys() {
  [[ -d "$HOME/.ssh" ]] || return 1
  local nonce=`date '+%Y%m%d_%s'`
  local github_user='candide-guevara'
  pushd "$HOME/.ssh"
  [[ -f authorized_keys ]] && rm authorized_keys

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
    run_cmd ssh-keygen -t rsa -b 4096 -f "$privkey" -C "${privkey}_${nonce}" -N "''"

    case "$privkey" in
    *arngrim*)
      cat "$pubkey" >> authorized_keys
      chmod og-wx authorized_keys
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
  done
  popd
  #access_token=bananas
  #colecho $txtylw "do not forget to delete the access token"
}

## Prints some nice bash shortcuts that I tend to forget ...
cheatsheat() {
  echo -e "### EDITING"
  echo -e "${bldcyn}Ctrl-a/Ctrl-e${txtrst} Go to the start and end of the line"
  echo -e "${bldcyn}Ctrl-k${txtrst}        Forward delete the whole line"
  echo -e "${bldcyn}Ctrl-s/Ctrl-q${txtrst} Disables/Enables keyboard input"
  echo -e "${bldcyn}Alt-f/Alt-b${txtrst}   Go forward/backward on words"
  echo -e "${bldcyn}Alt-d${txtrst}         Forward delete word"

  echo -e "\n### COMPLETION"
  echo -e "${bldcyn}Alt-Shift-4${txtrst}   Complete variables"
  echo -e "${bldcyn}Alt-/${txtrst}         Complete file names"
  echo -e "${bldcyn}Alt-Shift-{${txtrst}   Complete file names for brace expansion"

  echo -e "\n### JOBS"
  echo -e "${bldcyn}!*${txtrst}            Last command arguments"
  echo -e "${bldcyn}Ctrl-z${txtrst}        Suspend, ${bldcyn}<command>&${txtrst} to launch asynchronously"
  echo -e "${bldcyn}fg/bg${txtrst}         Resume on foreground/background"

  echo -e "\n### COMMANDS"
  echo -e "${bldcyn}type NAME${txtrst}     Tell if NAME is an alias/function/exe"
}

# Color manual pages
# See https://wiki.archlinux.org/index.php/Man_page#Using_less_.28Recommended.29
man() {
  env \
   LESS_TERMCAP_mb=$(printf $bldred) \
   LESS_TERMCAP_md=$(printf $bldred) \
   LESS_TERMCAP_me=$(printf $txtrst) \
   LESS_TERMCAP_se=$(printf $txtrst) \
   LESS_TERMCAP_so=$(printf $bkgwht$bldblu) \
   LESS_TERMCAP_ue=$(printf $txtrst) \
   LESS_TERMCAP_us=$(printf $bldgrn) \
   GROFF_NO_SGR=1 \
  man "$@"
}

## *USAGE: helpme [-f] [COMMAND_REGEX] 
## Creates the help text you are reading :-D
## The __-f__ flag will force the help file generation in case the scripts have changed
helpme() {
  # Cryptic, we just concat the 2 searches with a newline
  if [[ $IS_BLOOMBERG == 1 ]]; then
    find_options=( -type f -iname '*.sh' -or -iname '*.awk' -or -iname '*.py' )
  else
    find_options=( "-regextype" "posix-extended" "-type" "f" "-iregex" '.*(sh|py|awk)$' )
  fi
  local conffiles="`find $MY_ROOT_CONF_DIR $MY_ROOT_SCRIPT "${find_options[@]}" 2> /dev/null`"
  # run_cmd find $MY_ROOT_CONF_DIR $MY_ROOT_SCRIPT "${find_options[@]}" 2> /dev/null
  split_words "$conffiles"
  
  if [[ ! -f $TMP_HELP_FILE || $1 == "-f" ]]; then 
    set +o noclobber
    echo > $TMP_HELP_FILE
    for item in ${SPLIT_WORDS_RESULT[*]}; do
      local name=${item##*/}
      if regexmatch $name "sh$"; then
        gawk -f $AWK_COLOR_SCRIPT -f $AWK_MAN_FORMAT -v "FILE_TITLE=$name" $item  >> $TMP_HELP_FILE
        echo "Processing $item ..."
      fi  
    done
  fi

  local pattern="-p^"
  [[ $# -gt 0 ]] && [[ ! -z $2 || $1 != "-f" ]] && pattern="-p${2:-$1}"
  less $pattern $TMP_HELP_FILE
}

