#! /bin/bash
## Exports a hg repo into an existing git repo in a separate dir.

myhg() {
  echo "hg $@" 1>&2
  HGPLAIN=on hg "$@"
}
mygit() {
  echo "git $@" 1>&2
  git --no-pager "$@"
}

die_with_msg() {
  echo "[DIE] $@"
  exit 1
}

check_usage() {
  if [[ "$#" != 2 ]]; then
    echo "USAGE: ${0##*/} HGREPO GITREPO
    "
    exit 1
  fi
}
check_only_one_branch() {
  local branches=( `myhg branches | cut -d' ' -f1 | grep default` )
  [[ "${#branches[@]}" == 1 ]] \
    || die_with_msg "Cannot histories with many branches: ${branches[@]}"
}
check_no_merges() {
  local merge_revs=( `myhg log -r "merge()"` )
  [[ "${#merge_revs[@]}" == 0 ]] \
    || die_with_msg "Cannot handle merge histories: ${merge_revs[@]}"
}
check_diff_original_vs_exported() {
  echo "## Checking '$__hg_repo' vs '$__git_repo'
  "
  diff --exclude='.hg*' --ignore-all-space --brief \
    "$__hg_repo" "$__git_repo/$__dir_in_git" \
    | tee "$__diff_dir/diff_origin_dest.log"
}
check_no_files_modifed_outside_dir() {
  echo "## Files modified outside '$__dir_in_git'
  "
  pushd "$__git_repo" &> /dev/null
  mygit diff --name-only "${1}..HEAD" \
    | sort -u \
    | tee "$__diff_dir/modified_files.log" \
    | grep -vE "^${__dir_in_git}/"
  popd &> /dev/null
  echo "## ALL files modified count `wc -l "$__diff_dir/modified_files.log"`"
}
check_revision_count_matches() {
  local exported_count="`myhg log -r :tip | grep -E '^changeset:' | wc -l`"
  pushd "$__git_repo" &> /dev/null
  local imported_count="`mygit log --oneline "${1}..HEAD" | wc -l`"
  popd &> /dev/null
  [[ "$imported_count" == "$exported_count" ]] \
    || die_with_msg "check_revision_count_matches: imp='$imported_count' != exp='$exported_count'"
}
check_does_not_have_merge_conflict_markers() {
  local conflict_marker_log="$__diff_dir/conflict_marker.log"
  pushd "$__git_repo" &> /dev/null
  find "$__dir_in_git" -type f -print0 \
    | xargs --null -I{} grep --files-with-matches -E '<<<<<<<|=======|>>>>>>>' '{}' \
    | tee "$conflict_marker_log"
  popd &> /dev/null
  [[ "`cat "$conflict_marker_log" | wc -l`" == '0' ]] \
    || die_with_msg "Some files contain conflct markers"
}
check_can_be_pulled_to() {
  local ori_git_repo="$1"
  pushd "$ori_git_repo" &> /dev/null
  mygit pull --dry-run "$__git_repo" \
    || die_with_msg 'git pull failed'
  popd &> /dev/null
}

get_rev_description() {
  myhg log -r "$1" \
    | grep -E '^summary:' | sed -r 's/^[^:]+: +(.*)/\1/' \
    || die_with_msg "get_rev_description fail"
}
get_base_git_commit() {
  pushd "$__git_repo" &> /dev/null
  mygit rev-parse HEAD || die_with_msg "get_base_git_commit fail"
  popd &> /dev/null
}

call_for_all_revs_asc_order() {
  local all_revs=( `myhg log -r :tip | grep -E '^changeset:' | sed -r 's/.*:(.*)$/\1/'` )
  for arev in "${all_revs[@]}"; do
    echo "### REV=$arev"
    myhg log -r "$arev" &> debug || die_with_msg "rev='$arev' is not a valid revision"
    "$@" "$arev"
  done
}

apply_one_revfrom_hg_to_git() {
  local arev="$1"
  local revfile="$__diff_dir/$arev"
  local revdesc="[HG_EXPORT] `get_rev_description "$arev"`"
  hg export --git -r "$arev" -o "$revfile" \
    || die_with_msg "hg export fail: $arev"

  pushd "$__git_repo" &> /dev/null
  if mygit apply --directory="$__dir_in_git" --check --whitespace=fix "$revfile"; then
    mygit am --directory="$__dir_in_git" --whitespace=fix "$revfile" \
      || die_with_msg "git am fail: $arev"
    find "$__dir_in_git" -type f -name '*.orig' -print0 | xargs --null rm
    mygit commit --amend --message="$revdesc"
  else
    patch --merge --directory="$__dir_in_git" -p1 -u -i "$revfile"
    find "$__dir_in_git" -type f -name '*.orig' -print0 | xargs --null rm
    mygit add "$__dir_in_git"
    mygit commit --message="$revdesc" \
      || die_with_msg "git commit fail"
  fi
  popd &> /dev/null
}

create_staging() {
  local hg_repo="`readlink -f $1`"
  local git_repo="`readlink -f $2`"
  local hg_dirname="`basename "$hg_repo"`"
  local git_dirname="`basename "$git_repo"`"
  [[ -d "$hg_repo" ]] || die_with_msg "'hg_repo=$git_repo' is not a directory"
  [[ -d "$git_repo" ]] || die_with_msg "'git_repo=$git_repo' is not a directory"
  [[ -d "$git_repo/$hg_dirname" ]] && die_with_msg "'$git_dirname' is already a directory"

  __dir_in_git="$hg_dirname"
  __hg_repo="`mktemp --dry-run --tmpdir -d "hg_${hg_dirname}_XXXXXX"`"
  __git_repo="`mktemp --dry-run --tmpdir -d "git_${git_dirname}_XXXXXX"`"
  __diff_dir="`mktemp --tmpdir -d "diff_${hg_dirname}_XXXXXX"`"
  cp -rf "$git_repo" "$__git_repo" || die_with_msg "cp fail"
  cp -rf "$hg_repo" "$__hg_repo" || die_with_msg "cp fail"
}

final_report() {
  local ori_hg_repo="$1"
  local ori_git_repo="$2"
  echo "DONE
  __hg_repo='$__hg_repo'
  __git_repo='$__git_repo'
  __diff_dir='$__diff_dir'

  ( cd '$__git_repo' && git log )
  ( cd '$ori_git_repo' && git pull '$__git_repo' )
  "
}

main() {
  check_usage "$@"
  local ori_hg_repo="`readlink -f $1`"
  local ori_git_repo="`readlink -f $2`"
  create_staging "$ori_hg_repo" "$ori_git_repo"

  pushd "$__hg_repo" &> /dev/null
  local git_base="`get_base_git_commit`"
  check_only_one_branch
  check_no_merges
  call_for_all_revs_asc_order apply_one_revfrom_hg_to_git
  check_revision_count_matches "$git_base"
  check_does_not_have_merge_conflict_markers
  check_diff_original_vs_exported
  check_no_files_modifed_outside_dir "$git_base"
  check_can_be_pulled_to "$ori_git_repo"
  popd &> /dev/null

  final_report "$ori_hg_repo" "$ori_git_repo"
}
main "$@"

