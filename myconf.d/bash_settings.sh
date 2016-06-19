#! /bin/bash
## History and autocompletion options for bash.

export HISTFILESIZE=10000
export HISTSIZE=10000
export HISTCONTROL=erasedups

# enable programmable completion features
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
  . /etc/bash_completion
else
  complete -cf sudo
  complete -cf man
  complete -cf apropos
  complete -cf which
  complete -cf "type"
fi

# Auto completion for aliases
complete -p sc      &> /dev/null || complete -F _systemctl sc
complete -p btrfs   &> /dev/null || complete -F _btrfs_completion btrfs

# Auto completion for bloomberg tools
complete -f -X '!*.mk' plink

