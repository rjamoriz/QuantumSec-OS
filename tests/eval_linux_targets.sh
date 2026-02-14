#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

echo "[eval] linux iso drv"
drv="$("${NIX[@]}" eval --raw .#packages.x86_64-linux.quantumsec-iso.drvPath)"
echo "$drv"

echo "[eval] linux vmware-iso drv"
drv="$("${NIX[@]}" eval --raw .#packages.x86_64-linux.quantumsec-vmware-iso.drvPath)"
echo "$drv"

echo "[eval] linux vmware drv"
drv="$("${NIX[@]}" eval --raw .#packages.x86_64-linux.quantumsec-vmware.drvPath)"
echo "$drv"

echo "[eval] desktop toplevel drv"
drv="$("${NIX[@]}" eval --raw .#packages.x86_64-linux.quantumsec-desktop.drvPath)"
echo "$drv"

echo "[eval] headless toplevel drv"
drv="$("${NIX[@]}" eval --raw .#packages.x86_64-linux.quantumsec-headless.drvPath)"
echo "$drv"

echo "[eval] security summary headless drv"
drv="$("${NIX[@]}" eval --raw .#packages.x86_64-linux.quantumsec-security-summary-headless.drvPath)"
echo "$drv"

echo "[eval] security summary desktop drv"
drv="$("${NIX[@]}" eval --raw .#packages.x86_64-linux.quantumsec-security-summary-desktop.drvPath)"
echo "$drv"

echo "eval-linux-targets=ok"
