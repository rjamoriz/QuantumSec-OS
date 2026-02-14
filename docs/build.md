# Build and VMware Boot Guide

## 1) Lock and validate

```bash
nix flake lock
nix flake check
```

## 2) Build the QuantumSec installer ISO

```bash
nix build .#quantumsec-iso
```

The ISO artifact is produced from `packages.x86_64-linux.quantumsec-iso`.

On macOS, `nix build .#quantumsec-iso` intentionally produces a guidance artifact.
To target the real ISO output:

```bash
nix eval --raw .#packages.x86_64-linux.quantumsec-iso.drvPath
nix build .#packages.x86_64-linux.quantumsec-iso
```

## 3) Boot in VMware Fusion

1. Create a new VM and choose Linux (64-bit).
2. Use UEFI firmware mode.
3. Attach the built ISO from `./result/iso/*.iso`.
4. Allocate at least 4 vCPU and 8 GB RAM for simulator-heavy workloads.
5. Boot the VM.

## 4) Install for persistence

In the installer shell:

```bash
sudo -i
quantumsec-install-guide
```

Follow those commands to partition, format, mount, and run:

```bash
nixos-install --root /mnt --flake <this-repo>#quantumsec-vmware
```

This installs the persistent QuantumSec profile (not the live installer environment).

## 5) First boot checks after install

```bash
hostnamectl
systemctl status vmtoolsd
sshd -T | grep -E 'passwordauthentication|permitrootlogin|allowusers'
```

Expected:
- `passwordauthentication no`
- `permitrootlogin no`
- `allowusers quantum`
