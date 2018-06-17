## Defines some variables for color escape sequences
## Also has some utility functions to print in color

if [[ $IS_BASH == 1 ]]; then 
  export txtblk='\e[0;30m' # Black
  export txtred='\e[0;31m' # Red
  export txtgrn='\e[0;32m' # Green
  export txtylw='\e[0;33m' # Yellow
  export txtblu='\e[0;34m' # Blue
  export txtpur='\e[0;35m' # Purple
  export txtcyn='\e[0;36m' # Cyan
  export txtwht='\e[0;37m' # White
  export bldblk='\e[1;30m' # Bold Black
  export bldred='\e[1;31m' # Bold Red
  export bldgrn='\e[1;32m' # Bold Green
  export bldylw='\e[1;33m' # Bold Yellow
  export bldblu='\e[1;34m' # Bold Blue
  export bldpur='\e[1;35m' # Bold Purple
  export bldcyn='\e[1;36m' # Bold Cyan
  export bldwht='\e[1;37m' # Bold White
  export bkgred='\e[41m'   # Background red
  export bkggrn='\e[42m'   # Background green
  export bkgylw='\e[43m'   # Background yellow
  export bkgblu='\e[44m'   # Background blue
  export bkgpur='\e[45m'   # Background purple
  export bkgcyn='\e[46m'   # Background purple
  export bkgwht='\e[47m'   # Background white
  export txtrst='\e[0m'    # Text Reset

  export sed_txtblk=$'\e[0;30m' # Black
  export sed_txtred=$'\e[0;31m' # Red
  export sed_txtgrn=$'\e[0;32m' # Green
  export sed_txtylw=$'\e[0;33m' # Yellow
  export sed_txtblu=$'\e[0;34m' # Blue
  export sed_txtpur=$'\e[0;35m' # Purple
  export sed_txtcyn=$'\e[0;36m' # Cyan
  export sed_txtwht=$'\e[0;37m' # White
  export sed_bldblk=$'\e[1;30m' # Bold Black
  export sed_bldred=$'\e[1;31m' # Bold Red
  export sed_bldgrn=$'\e[1;32m' # Bold Green
  export sed_bldylw=$'\e[1;33m' # Bold Yellow
  export sed_bldblu=$'\e[1;34m' # Bold Blue
  export sed_bldpur=$'\e[1;35m' # Bold Purple
  export sed_bldcyn=$'\e[1;36m' # Bold Cyan
  export sed_bldwht=$'\e[1;37m' # Bold White
  export sed_bkgred=$'\e[41m'   # Background red
  export sed_bkggrn=$'\e[42m'   # Background green
  export sed_bkgylw=$'\e[43m'   # Background yellow
  export sed_bkgblu=$'\e[44m'   # Background blue
  export sed_bkgpur=$'\e[45m'   # Background purple
  export sed_bkgcyn=$'\e[46m'   # Background purple
  export sed_bkgwht=$'\e[47m'   # Background white
  export sed_txtrst=$'\e[0m'    # Text Reset

  # When using zsh the prompt is set in zshellmisc
  # We change prompt color for root account
  if [[ `id -u` == "0" ]]; then
    export PS1="${bldred}\u@\h : \w\$${txtrst}\n  "
  # We change prompt if connected from ssh
  elif [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" ]]; then
    export PS1="${bldgrn}\u@\h : \w\$${txtrst}\n  "
  else
    export PS1="${bldblu}\u@\h : \w\$${txtrst}\n  "
  fi

fi

if [[ $IS_ZSH == 1 ]]; then
  autoload -U colors && colors
  export txtblk=$fg_no_bold[black]    # Black
  export txtred=$fg_no_bold[red]      # Red
  export txtgrn=$fg_no_bold[green]    # Green
  export txtylw=$fg_no_bold[yellow]   # Yellow
  export txtblu=$fg_no_bold[blue]     # Blue
  export txtpur=$fg_no_bold[magenta]  # Purple
  export txtcyn=$fg_no_bold[cyan]     # Cyan
  export txtwht=$fg_no_bold[white]    # White
  export bldblk=$fg_bold[black]       # Bold Black
  export bldred=$fg_bold[red]         # Bold Red
  export bldgrn=$fg_bold[green]       # Bold Green
  export bldylw=$fg_bold[yellow]      # Bold Yellow
  export bldblu=$fg_bold[blue]        # Bold Blue
  export bldpur=$fg_bold[magenta]     # Bold Purple
  export bldcyn=$fg_bold[cyan]        # Bold Cyan
  export bldwht=$fg_bold[white]       # Bold White
  export bkgred=$bg_bold[red]         # Background red
  export bkggrn=$bg_bold[green]       # Background green
  export bkgylw=$bg_bold[yellow]      # Background yellow
  export bkgblu=$bg_bold[blue]        # Background blue
  export bkgpur=$bg_bold[magenta]     # Background purple
  export bkgcyn=$bg_bold[cyan]        # Background purple
  export bkgwht=$bg_bold[white]       # Background white
  export txtrst=$reset_color          # Text Reset
fi

## *USAGE: errecho MESSAGE
errecho() {
  echo -e "${bldred}$@${txtrst}"
}

## *USAGE: colecho COLOR MESSAGE
colecho() {
  local color=$1
  shift
  echo -e "${color}$@${txtrst}"
}
