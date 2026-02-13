# Hardening Baseline

This document explains the security posture implemented in v1.

## Network and remote access

- Firewall enabled (`networking.firewall.enable = true`): default deny inbound unless explicitly opened.
- ICMP ping blocked by default (`allowPing = false`) to reduce trivial host discovery.
- OpenSSH hardened:
  - `PasswordAuthentication = false`
  - `KbdInteractiveAuthentication = false`
  - `PermitRootLogin = "no"`
  - `AllowTcpForwarding = "no"`
  - `AllowAgentForwarding = false`
  - Lower `MaxAuthTries` and short `LoginGraceTime`

## Nix hardening

- Nix sandbox enabled (`nix.settings.sandbox = true`) for isolated builds.
- Trusted users restricted to `root` and `@wheel`.
- Allowed Nix users restricted to `@wheel` to avoid arbitrary local build users.
- Flakes + nix-command explicitly enabled.

## Kernel/sysctl hardening

Applied in `nix/modules/security.nix`:

- `kernel.kptr_restrict = 2`: restrict kernel pointer exposure.
- `kernel.dmesg_restrict = 1`: block unprivileged kernel log access.
- `kernel.unprivileged_bpf_disabled = 1` and `net.core.bpf_jit_harden = 2`: reduce BPF abuse risk.
- `kernel.sysrq = 0`: disable magic SysRq in normal operation.
- `fs.protected_*` settings: improve link/FIFO safety.
- `net.ipv4.tcp_syncookies = 1`: protect against SYN floods.
- Disable IPv4/IPv6 redirects and enable IPv4 rp_filter.
- Ignore suspicious/bogus ICMP behaviors.

## systemd service hardening

Custom service `quantumsec-baseline-report` is explicitly hardened:

- `NoNewPrivileges=true`
- `PrivateTmp=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `ProtectKernelTunables=true`
- `ProtectControlGroups=true`
- `LockPersonality=true`
- `RestrictSUIDSGID=true`
- Uses a dedicated state directory (`/var/lib/quantumsec`)

## Research sandbox pattern (v1)

Chosen approach: rootless Podman containers for untrusted notebooks/tools.

- Podman is enabled without Docker socket compatibility.
- Researchers run untrusted tools in rootless containers instead of host Python.
- Quantum framework development remains in Nix dev shells to keep dependency closure reproducible.

## Notes

- `users.mutableUsers = true` is set to avoid lockout during first boot; after provisioning SSH keys/passwords, you can switch to immutable users.
- User accounts are intentionally declared with `hashedPassword = "!"` as a safe default; set SSH keys before deployment.
- Security-relevant changes should be reflected here and in commit messages.
