#!/bin/bash
## Copies files specific to the work repo

HOME_REPO_ROOT="."
WORK_REPO_ROOT="`readlink -f "$1"`"
COPY_ROOT="$HOME_REPO_ROOT/google"

if [[ ! -d "$WORK_REPO_ROOT" ]]; then
  echo "[ERROR] '$WORK_REPO_ROOT' does not exist"
  exit 1
fi

if [[ ! -d "$COPY_ROOT" ]]; then
  echo "[ERROR] '$COPY_ROOT' does not exist"
  exit 1
fi

pushd "$COPY_ROOT"
for file in `find -type f`; do
  work_copy="$WORK_REPO_ROOT/$file"
  echo "$work_copy -> $COPY_ROOT/$file"
  if [[ -f "$work_copy" ]]; then
    cp "$work_copy" "$file"
  else
    echo "[ERROR] '$work_copy' is not a file"
  fi
done
popd
