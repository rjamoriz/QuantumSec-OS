#!/usr/bin/env bash
set -euo pipefail

failures=0

check_equals() {
  local label="$1"
  local actual="$2"
  local expected="$3"

  if [[ "$actual" == "$expected" ]]; then
    printf '[ok]   %s: %s\n' "$label" "$actual"
  else
    printf '[fail] %s: expected=%s actual=%s\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf '[fail] missing command: %s\n' "$cmd"
    failures=$((failures + 1))
  fi
}

require_cmd sshd
require_cmd systemctl
require_cmd sysctl

if (( failures > 0 )); then
  printf 'host-hardening-audit=failed (missing prerequisites)\n'
  exit 1
fi

ssh_password_auth="$(sshd -T | awk '/^passwordauthentication / {print $2}')"
ssh_kbd_auth="$(sshd -T | awk '/^kbdinteractiveauthentication / {print $2}')"
ssh_root_login="$(sshd -T | awk '/^permitrootlogin / {print $2}')"

check_equals "ssh.passwordauthentication" "$ssh_password_auth" "no"
check_equals "ssh.kbdinteractiveauthentication" "$ssh_kbd_auth" "no"
check_equals "ssh.permitrootlogin" "$ssh_root_login" "no"

if systemctl is-enabled firewall >/dev/null 2>&1; then
  check_equals "firewall.is-enabled" "enabled" "enabled"
else
  check_equals "firewall.is-enabled" "disabled" "enabled"
fi

if systemctl is-enabled quantumsec-baseline-report.timer >/dev/null 2>&1; then
  check_equals "timer.quantumsec-baseline-report" "enabled" "enabled"
else
  check_equals "timer.quantumsec-baseline-report" "disabled" "enabled"
fi

kptr="$(sysctl -n kernel.kptr_restrict 2>/dev/null || echo missing)"
dmesg="$(sysctl -n kernel.dmesg_restrict 2>/dev/null || echo missing)"
bpf="$(sysctl -n kernel.unprivileged_bpf_disabled 2>/dev/null || echo missing)"

check_equals "sysctl.kernel.kptr_restrict" "$kptr" "2"
check_equals "sysctl.kernel.dmesg_restrict" "$dmesg" "1"
check_equals "sysctl.kernel.unprivileged_bpf_disabled" "$bpf" "1"

if command -v nix >/dev/null 2>&1; then
  sandbox="$(nix show-config 2>/dev/null | awk -F ' = ' '/^sandbox = / {print $2}')"
  check_equals "nix.sandbox" "$sandbox" "true"
else
  printf '[warn] nix command unavailable; skipping nix.sandbox check\n'
fi

if (( failures > 0 )); then
  printf 'host-hardening-audit=failed (%d checks)\n' "$failures"
  exit 1
fi

printf 'host-hardening-audit=ok\n'
