#! /bin/bash
## Check source control repos are in sync between my machines and github

## *USAGE: hg_check_other_host_uptodate
## Finds all hg repos under the current directory and checks they are in sync between machines.
hg_check_all_other_host_uptodate() {
  local -a repo_roots=( `__find_repos_under_dir__ . '.hg'` )
  ssh_agent_load_key "arngrim_id_rsa"
  for repo in "${repo_roots[@]}"; do
  colecho $txtcyn "CHECKING '${repo}'"
  __pushd__ "$repo" || continue
    hg_check_other_host_uptodate . \
      || colecho $txtylw "[WARN] '$repo' failed to check other host"
  popd &> /dev/null
  done
  colecho $txtcyn "DONE ${#repo_roots[@]} checked"
}

## *USAGE: git_check_all_pushed
## Finds all git repos under the current directory and checks all modifications either:
## * Have been pushed to github
## * Are in sync between machines (if the repo is not available on github)
git_check_all_in_sync() {
  local -a repo_roots=( `__find_repos_under_dir__ . '.git'` )
  ssh_agent_load_key "arngrim_id_rsa" "global_github"

  for repo in "${repo_roots[@]}"; do
  colecho $txtcyn "CHECKING '${repo}'"
  __pushd__ "$repo" || return 1
    local modified_tracked="`git status --porcelain --untracked-files=no`"
    if [[ ! -z "${modified_tracked}" ]]; then
      colecho $txtylw "[WARN] '$repo' has modification to tracked files"
      echo "${modified_tracked}"
    fi
    if ! git remote --verbose | grep 'git@github.com' > /dev/null; then
      git_check_other_host_uptodate . \
        || colecho $txtylw "[WARN] '$repo' failed to check other host"
      popd &> /dev/null
      continue
    fi
    if ! git fetch --all > /dev/null; then
      errecho "Failed to fetch branches for '$repo'"
      popd &> /dev/null
      return 1
    fi
    local -a remote_branches=( `git branch --remote | sed -r 's/^[ *]*([^ ]+).*/\1/'` )
    __git_check_remote_branches__ "${remote_branches[@]}"
  popd &> /dev/null
  done
  colecho $txtcyn "DONE ${#repo_roots[@]} checked"
}

## *USAGE: hg_check_other_host_uptodate REPOPATH
## Checks the same repo on my other machine is in sync with this one.
hg_check_other_host_uptodate() {
  local repo_this_host="`readlink -f "$1"`"
  local repo_name="`basename "$repo_this_host"`"
  local repo_other_host="${repo_this_host#$HOME/}"
  __other_host__ "$repo_other_host" || return 1
  __pushd__ "$repo_this_host" || return 1
    diff --unified \
      --label "`hostname`"  <( HGPLAIN=on hg branches ) \
      --label "$other_host" <( ssh "$other_host" "cd '$repo_other_host' && HGPLAIN=on hg branches" )
  popd &> /dev/null
}

## *USAGE: git_check_other_host_uptodate REPOPATH
## Checks the same repo on my other machine is in sync with this one.
git_check_other_host_uptodate() {
  local repo_this_host="`readlink -f "$1"`"
  local repo_name="`basename "$repo_this_host"`"
  local repo_other_host="${repo_this_host#$HOME/}"
  __other_host__ "$repo_other_host" || return 1

  __pushd__ "$repo_this_host" || return 1
  git remote add "$other_host" "${USER}@${other_host}:${repo_other_host}" \
    || return 1
  git fetch "$other_host" > /dev/null
  local -a remote_branches=( `git branch --remote | grep "$other_host" | sed -r 's/^[ *]*([^ ]+).*/\1/'` )
  __git_check_remote_branches__ --both-ways "${remote_branches[@]}"
  git remote remove "$other_host" || return 1
  echo "git_sync_host --dry-run '$other_host' '$repo_this_host'"
  popd &> /dev/null
}

## *USAGE: git_sync_host [--dry-run] [--no-ssh] HOST REPOPATH
## Syncs git REPOPATH between this machine and HOST.
git_sync_host() {
  if [[ "$1" == "--dry-run" ]] || [[ "$2" == "--dry-run" ]]; then
    shift
    local dry_run="--dry-run"
  fi
  if [[ "$1" == "--no-ssh" ]] || [[ "$2" == "--no-ssh" ]]; then
    shift
    local no_ssh=1
  fi
  local other_host="$1"
  local repo_full_path="$2"
  local this_host="`hostname`"
  local repo_path="${repo_full_path#$HOME/}"

  __pushd__ "$repo_full_path" || return 1
  run_cmd git remote add "$other_host" "${USER}@${other_host}:${repo_path}"
  git fetch "$other_host"
  local -a remote_branches=( `git branch --remote | grep "$other_host" | sed -r 's/^[ *]*([^ ]+).*/\1/'` )
  for branch in "${remote_branches[@]}"; do
    local local_branch="`basename "$branch"`"
    git checkout "$local_branch" || break
    run_cmd git pull $dry_run --autostash "$other_host" "$local_branch" || break
  done
  git remote remove "$other_host"
  popd &> /dev/null

  # Be careful it is a trap ! Git will refuse to push to the other repo
  # (maybe because it can clobber working dir changes ?)
  # This is why we need to 'pull' from both sides instead of 'pull/push'.
  if [[ -z "$no_ssh" ]]; then
    __error_if_unreachable__ "$other_host" || return 1
    # Uses agent forwarding so it expects this host to have the maste git key loaded on its agent
    run_cmd ssh -o ForwardAgent=yes "$other_host" \
      bash --login -c "\"git_sync_host $dry_run --no-ssh '$this_host' '$repo_path'\""
  fi
}

# *USAGE: __git_check_remote_branches__ [--both-ways] BRANCHES
# Checks if there are commit differences between the local and remote branches.
# Expects current dir the root of the repo to check.
__git_check_remote_branches__() {
  if [[ "$1" == "--both-ways" ]]; then
    shift
    local both_ways=1
  fi
  for branch in "$@"; do
    local local_branch="`basename "$branch"`"
    local -a ranges=( "${branch}..${local_branch}" )
    [[ -z "$both_ways" ]] || ranges+=( "${local_branch}..${branch}" )

    if ! git branch | grep -E " $local_branch\$" > /dev/null; then
      errecho "In '`basename $PWD`' remote branch '$branch' does not match any local branch (expected '$local_branch')"
      popd &> /dev/null
      return 1
    fi

    for rev_range in "${ranges[@]}"; do
      local missing_changes="`git log --pretty=oneline "$rev_range"`"
      if [[ ! -z "${missing_changes}" ]]; then
        colecho $txtylw "[WARN] '`basename ${PWD}`:${branch}' '$rev_range' misses changes :"
        echo "${missing_changes}"
      fi
    done
  done
}

# *USAGE: __other_host__ repo_path
# Sets the `other_host` global var (repo_path is relative from the user's home).
__other_host__() {
  local repo_path="$1"
  other_host="llewelyn"
  [[ "`hostname`" == "$other_host" ]] && other_host="arngrim"
  __error_if_unreachable__ "$other_host" || return 1
  if ! ssh "$other_host" test -d "$repo_path"; then
    errecho "'$other_host'@'$repo_path' is not available"
    return 1
  fi
}

# *USAGE: __find_repos_under_dir__ DIR MARKER
# Prints all repos found under DIR.
__find_repos_under_dir__() {
  local dir="$1"
  local marker="$2"
  find "$dir" -type d -name "$marker" -print0 \
    | xargs -0 dirname \
    | sed -r 's/ /_REMOVE_THIS_FCKING_SPACE_/g'
}

# *USAGE: __pushd__ DIR
# Like pushd but verbose
__pushd__() {
  if [[ ! -d "$1" ]]; then
    errecho "pushd='$1' is not a directory"
    return 1
  fi
  pushd "$1" &> /dev/null
}
