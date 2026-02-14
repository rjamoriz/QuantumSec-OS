#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-headless}"

case "$TARGET" in
  headless)
    ATTR="quantumsec-security-summary-headless"
    ;;
  desktop)
    ATTR="quantumsec-security-summary-desktop"
    ;;
  *)
    echo "usage: $0 [headless|desktop]"
    exit 1
    ;;
esac

if command -v nix >/dev/null 2>&1; then
  NIX_BIN="$(command -v nix)"
elif [[ -x "/nix/var/nix/profiles/default/bin/nix" ]]; then
  NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
else
  echo "nix is required"
  exit 1
fi

NIX=("$NIX_BIN" --extra-experimental-features "nix-command flakes")

cd "$REPO_ROOT"

"${NIX[@]}" build ".#${ATTR}" >/dev/null

if [[ -f result ]]; then
  cat result
  rm -f result
else
  echo "failed to locate build result"
  exit 1
fi
