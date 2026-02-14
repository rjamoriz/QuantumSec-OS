#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

tracked_files=()
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r file; do
    tracked_files+=("$file")
  done < <(git -C "$REPO_ROOT" ls-files)
else
  while IFS= read -r file; do
    tracked_files+=("$file")
  done < <(find . -type f -not -path './.git/*' -print | sed 's#^./##')
fi

if (( ${#tracked_files[@]} == 0 )); then
  printf 'scan-for-secrets=ok (no files)\n'
  exit 0
fi

RG_BIN="${RG_BIN:-}"
if [[ -z "$RG_BIN" ]]; then
  if command -v rg >/dev/null 2>&1; then
    RG_BIN="$(command -v rg)"
  else
    echo "ripgrep (rg) is required"
    exit 1
  fi
fi

failures=0

scan_regex() {
  local label="$1"
  local regex="$2"

  local output
  if output="$($RG_BIN --line-number --color never --no-heading --regexp "$regex" -- "${tracked_files[@]}" 2>/dev/null || true)"; then
    :
  fi

  if [[ -n "$output" ]]; then
    printf '[fail] %s\n' "$label"
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

scan_path_regex() {
  local label="$1"
  local regex="$2"

  local matched=0
  for file in "${tracked_files[@]}"; do
    if [[ "$file" =~ $regex ]]; then
      if (( matched == 0 )); then
        printf '[fail] %s\n' "$label"
      fi
      matched=1
      printf '%s\n' "$file"
    fi
  done

  if (( matched == 1 )); then
    failures=$((failures + 1))
  fi
}

scan_regex "private key material" '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
scan_regex "aws access key id" 'AKIA[0-9A-Z]{16}'
scan_regex "github personal access token" 'ghp_[A-Za-z0-9]{36}'
scan_regex "slack token" 'xox[baprs]-[A-Za-z0-9-]{10,}'
scan_regex "google api key" 'AIza[0-9A-Za-z_-]{35}'

scan_path_regex "tracked dotenv files are not allowed" '(^|/)\.env(\.|$)'
scan_path_regex "tracked private key-like filenames are not allowed" '(^|/)(id_rsa|id_dsa|id_ecdsa|id_ed25519|.*\.pem|.*\.key)$'

if (( failures > 0 )); then
  printf 'scan-for-secrets=failed (%d findings)\n' "$failures"
  exit 1
fi

printf 'scan-for-secrets=ok\n'
