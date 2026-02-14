# Operations Runbook

This runbook covers first-boot and post-deployment checks for QuantumSec OS hosts.

## 1) First boot checklist

1. Login locally or through a trusted console.
2. Add SSH keys for the `researcher` user.
3. Verify no password-based SSH login is possible.
4. Confirm firewall is enabled.

## 2) Add SSH authorized key

```bash
sudo install -d -m 700 /home/researcher/.ssh
sudo install -m 600 /dev/stdin /home/researcher/.ssh/authorized_keys <<'KEY'
ssh-ed25519 AAAA... replace-with-real-key
KEY
sudo chown -R researcher:users /home/researcher/.ssh
```

## 3) Run baseline audit on host

```bash
nix run .#host-hardening-audit
# or directly
./scripts/host_hardening_audit.sh
```

Expected result:

```text
host-hardening-audit=ok
```

Timer checks are included in the audit. Manual inspection:

```bash
systemctl status quantumsec-baseline-report.timer
```

You can inspect evaluated policy snapshots without booting:

```bash
nix run .#show-security-summary -- headless  # x86_64-linux
nix run .#show-security-summary -- desktop   # x86_64-linux
nix run .#show-security-summary -- vmware    # x86_64-linux
```

## 4) Optional: switch to immutable users after provisioning

`users.mutableUsers = true` is used by default to avoid lockout on first boot.
After user credentials and keys are provisioned, you can switch to immutable users:

1. Set `users.mutableUsers = false` in `nix/modules/security.nix`.
2. Ensure each managed account has explicit key/password configuration.
3. Rebuild and deploy.

## 5) Artifact build pipeline (Linux host)

```bash
nix run .#build-linux-artifacts
```

This runs checks, evaluates targets, builds ISO/VMware images, and builds security summaries.
