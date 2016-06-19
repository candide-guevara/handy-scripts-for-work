#! /bin/bash
## Custom autocompletion options for shell commands. See also bash_settings.sh

COMP_BTRFS_CMD=( `btrfs --help | sed -rn 's/^[[:space:]]*btrfs[[:space:]]*//p' | cut -d" " -f1 | sort -u` )
COMP_BTRFS_SUBCMD=( `btrfs --help | sed -rn 's/\[[^]]+\]//g ; s/^[[:space:]]*btrfs[[:space:]]*//p' | cut -d" " --output-delimiter "::" -f1,2` )

## *USAGE : _btrfs_completion CMD CURRENT PREVIOUS
## Bash completion (see man) function for btrfs user tools
_btrfs_completion() {
  if [[ "${#COMP_WORDS[@]}" == 3 ]]; then
    __btrfs_comp_subcmd "$2" "$3"
  else
    COMPREPLY=( `compgen -W "${COMP_BTRFS_CMD[*]}" "$2"` )
  fi
}

# *USAGE : __btrfs_comp_subcmd CURRENT PREVIOUS
# Completes btrfs sub commands
__btrfs_comp_subcmd() {
  local -a result
  for token in "${COMP_BTRFS_SUBCMD[@]}"; do
    if [[ "$token" == "$2"* ]]; then
      local subcmd="${token#*::}"
      [[ -z "$subcmd" ]] || result+=( "$subcmd" )
    fi
  done
  COMPREPLY=( `compgen -W "${result[*]}" "$1"` )
}

