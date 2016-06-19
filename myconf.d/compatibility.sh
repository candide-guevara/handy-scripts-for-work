## Functions to intriduce a compatibility layer between bash and zsh.
## The routines here must not depend on anything except global variables 
## so that this file may be sourced to standalone scripts.

## *USAGE regexmatch STRING REGEX
## __Ugly__ shell independent slow implementation :-(
## Returns 0 if REGEX matches STRING
regexmatch() {
  echo $1 | gawk "BEGIN {IGNORECASE=1} !/$2/ {exit 1}"
}

## *USAGE substring STRING START LENGTH
## Extract substring from variable. The result goes in SUBSTR_RESULT
substring() {
  if [[ $IS_ZSH == 1 ]]; then
    local zsh_start=$(( $2 + 1 ))
    local zsh_end=$(( $2 + $3 ))
    SUBSTR_RESULT=${1[$zsh_start, $zsh_end]}
  else
    SUBSTR_RESULT=${1:$2:$3}
  fi
}

## Converts the argument to lower case and outputs the result in TOLOWER_RESULT
tolower() {
  if [[ $IS_ZSH == 1 ]]; then
    TOLOWER_RESULT=${(L)1}
  else
    # ^^ and ,, are not available in bash 3
    TOLOWER_RESULT=`echo "$1" | tr '[[:upper:]]' '[[:lower:]]'`
  fi
}

## Converts the argument to upper case and outputs the result in TOUPPER_RESULT
toupper() {
  if [[ $IS_ZSH == 1 ]]; then
    TOUPPER_RESULT=${(U)1}
  else
    # ^^ and ,, are not available in bash 3
    TOUPPER_RESULT=`echo "$1" | tr '[[:lower:]]' '[[:upper:]]'`
  fi
}

## *USAGE: setoption [NO]OPTION
## Sets shell options. Internally calls the right shell option setter builtin
setoption() {
  case $1 in
    glob) set +o noglob ;;
    noglob) set -o noglob ;;
    xtrace) set -o xtrace ;;
    noxtrace) set +o xtrace ;;

    caseglob)
      [[ $IS_ZSH == 1 ]] && setopt caseglob
      [[ $IS_BASH == 1 ]] && shopt -u nocaseglob ;;
    nocaseglob)
      [[ $IS_ZSH == 1 ]] && setopt nocaseglob
      [[ $IS_BASH == 1 ]] && shopt -s nocaseglob ;;
    shwordsplit)
      [[ $IS_ZSH == 1 ]] && setopt shwordsplit ;;
    noshwordsplit)
      [[ $IS_ZSH == 1 ]] && setopt noshwordsplit ;;
    *)
      errecho "Option $1 is unknown in zsh" ;;
  esac
}

## *USAGE: get_option OPTION (do __not__ use the nooption form)
## Returns the value of a shell option in variable OPTION_RESULT.
## get_option "some_option"; setoption $OPTION_RESULT => does not change anything
get_option() {
  [[ $IS_ZSH == 1 ]] && local options="` set -o `"
  [[ $IS_BASH == 1 ]] && local options="` shopt -o; shopt `"

  local value="` echo "$options" | grep --extended-regexp "^$1\b" | gawk '{ print $2 }' `"
  local no_value="` echo "$options" | grep --extended-regexp "^no$1\b" | gawk '{ print $2 }' `"

  [[ $value == "on"  || $no_value == "off" ]] && local result=$1
  [[ $value == "off" || $no_value == "on" ]] && local result="no$1"
  [[ -z $result ]] && errecho "Option $1 is unknown"
  OPTION_RESULT=$result
}

## *USAGE: split_words [--space|--newline|--tab|--null] LIST_OF_WORDS
## If no separator token is given then the default is newline
## Handy function to split a list of word using different tokens into an array
split_words() {
  local backup="$IFS"
  case $1 in
    --space)  IFS=' '   ;;
    --tab)    IFS=$'\t' ;;
    --null)   IFS=$'\0' ;;
    *)        IFS=$'\n' ;;
  esac

  setoption noglob
  setoption shwordsplit
  SPLIT_WORDS_RESULT=''
  SPLIT_WORDS_RESULT=( ${2:-$1} )
  setoption glob
  setoption noshwordsplit

  if [[ ! -z $backup ]]; then
    IFS="$backup"
  else
    unset IFS
  fi
  [[ ${#SPLIT_WORDS_RESULT[@]} < 1 ]] && errecho "split_words may have failed for '${2:-$1}'"
}

