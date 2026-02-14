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

print_target() {
  local name="$1"
  local attr="$2"
  local drv
  local out

  drv="$("${NIX[@]}" eval --raw ".#packages.x86_64-linux.${attr}.drvPath")"
  out="$("${NIX[@]}" eval --raw ".#packages.x86_64-linux.${attr}.outPath")"

  echo "[$name]"
  echo "  attr    : packages.x86_64-linux.${attr}"
  echo "  drvPath : ${drv}"
  echo "  outPath : ${out}"
}

print_target "VMware Installer ISO" "quantumsec-vmware-iso"
echo
print_target "VMware VMDK Image" "quantumsec-vmware"
echo
echo "Build commands:"
echo "  nix build .#quantumsec-vmware-iso"
echo "  nix build .#quantumsec-vmware"
