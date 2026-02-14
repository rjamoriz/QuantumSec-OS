# Hardening Baseline (v1)

This document explains the security posture implemented by `nix/modules/security.nix` and related modules.

## Network and SSH

- Firewall enabled by default:
  - `networking.firewall.enable = true`
  - `networking.firewall.allowPing = false`
- OpenSSH enabled with hardening:
  - `PasswordAuthentication = false`
  - `KbdInteractiveAuthentication = false`
  - `PermitRootLogin = "no"`
  - `AllowUsers = [ "quantum" ]`
  - `AllowAgentForwarding = false`
  - `AllowTcpForwarding = "no"`

This keeps remote access key-only while still allowing local console login.

## Nix hardening

- `nix.settings.sandbox = true`
- `trusted-users = [ "root" "@wheel" ]`
- `allowed-users = [ "@wheel" ]`
- flakes + `nix-command` enabled explicitly

## Kernel/sysctl hardening

- `kernel.kptr_restrict = 2`
- `kernel.dmesg_restrict = 1`
- `kernel.unprivileged_bpf_disabled = 1`
- `net.core.bpf_jit_harden = 2`
- `kernel.sysrq = 0`
- `fs.protected_fifos = 2`
- `fs.protected_hardlinks = 1`
- `fs.protected_symlinks = 1`
- `net.ipv4.tcp_syncookies = 1`
- Redirects disabled (`accept_redirects` and `send_redirects`)
- IPv4 reverse path filter enabled (`rp_filter`)

These reduce common local privilege-escalation and network attack surfaces without blocking normal VM workflows.

## Minimal services

- Disabled by default:
  - printing (`services.printing.enable = false`)
  - Avahi/mDNS (`services.avahi.enable = false`)
- Optional AppArmor support enabled:
  - `security.apparmor.enable = true`

## VMware guest readiness

`nix/modules/vmware.nix` enables:
- `services.open-vm-tools.enable = true`
- `virtualisation.vmware.guest.enable = true`
- VMware initrd modules (`vmw_pvscsi`, `vmxnet3`)

## v1 convenience credential

User `quantum` is configured with initial password `quantum` for first-boot VM convenience.

You should change it immediately after install:

```bash
passwd quantum
```
