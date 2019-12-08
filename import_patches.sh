#! /bin/bash
## Imports changesets from original blog repo

REPO_DIR="$1"
shift
COMMIT=( "$@" )

[[ -d "$REPO_DIR" ]] || exit 1

pushd "$REPO_DIR"
PATCHES=( `git format-patch "${COMMIT[@]}"` )
[[ ${#PATCHES[@]} -gt 0 ]] || exit 2
popd

echo "
Apply patches ?  
${PATCHES[@]}"
read -p "y/n ? " go_for_it
[[ "$go_for_it" == 'y' ]] || exit 6

for patch in "${PATCHES[@]}"; do
  echo "Processing patch : $patch"
  mv "$REPO_DIR/$patch" . || exit 3
  if ! git apply --check --verbose "$patch"; then
    echo "Failed, try patching manually : "
    echo "patch --merge -p1 -u -i '$patch'"
    exit 4
  fi
  git am --ignore-whitespace "$patch" || exit 5
done

