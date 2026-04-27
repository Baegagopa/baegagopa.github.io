#!/usr/bin/env sh
set -eu

mode="${1:-tracked}"
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

private_prefixes='^CrossPromoTools/'

case "$mode" in
  tracked)
    candidates=$(git ls-files)
    ;;
  *)
    printf '%s
' "Unsupported mode: $mode" >&2
    exit 2
    ;;
esac

matches=$(printf '%s
' "$candidates" | grep -E "$private_prefixes" || true)

if [ -n "$matches" ]; then
  printf '%s
' 'ERROR: private tooling paths are selected for public Git tracking.' >&2
  printf '%s
' 'The public repo must not track anything under CrossPromoTools/.' >&2
  printf '%s
' 'Offending paths:' >&2
  printf '%s
' "$matches" >&2
  exit 1
fi
