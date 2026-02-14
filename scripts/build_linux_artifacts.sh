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

echo "[1/4] flake check"
"${NIX[@]}" flake check --print-build-logs

echo "[2/4] evaluate linux targets"
"${NIX[@]}" run .#eval-linux-targets

echo "[3/4] build linux images"
"${NIX[@]}" build .#quantumsec-iso .#quantumsec-vmware-iso .#quantumsec-vmware --print-build-logs

echo "[4/4] build security summaries"
"${NIX[@]}" build .#quantumsec-security-summary-headless .#quantumsec-security-summary-desktop --print-build-logs

echo "build-linux-artifacts=ok"
