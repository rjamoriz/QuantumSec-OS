# VMware Deployment Guide

This guide focuses on running QuantumSec OS in VMware using either an installer ISO or a prebuilt VMDK image.

## Choose your deployment path

- ISO-first install (recommended for controlled installs):
  - Build `.#quantumsec-vmware-iso`
  - Install onto a new virtual disk
- Prebuilt image (fastest bring-up):
  - Build `.#quantumsec-vmware`
  - Import the resulting VMDK into a VM

## Inspect evaluated artifact paths

From repo root:

```bash
nix run .#show-vmware-artifacts
```

This prints evaluated `drvPath` and `outPath` values for:

- `packages.x86_64-linux.quantumsec-vmware-iso`
- `packages.x86_64-linux.quantumsec-vmware`

## VMware VM settings (baseline)

Use these as a starting point for both install paths:

- Firmware: UEFI
- vCPU: 4
- RAM: 8-16 GiB
- Disk: 80+ GiB (NVMe or SCSI)
- Network: NAT for isolated testing, Bridged for direct LAN access
- 3D acceleration: optional (enable for desktop profile)

## ISO-first workflow

1. Build ISO:
   ```bash
   nix build .#quantumsec-vmware-iso
   ```
2. Attach ISO from `result/iso/*.iso` (path may vary by nixpkgs revision).
3. Create a blank virtual disk and boot installer.
4. Provision SSH keys for `researcher`.
5. Reboot into installed system and run host checks:
   ```bash
   nix run .#host-hardening-audit
   systemctl status vmtoolsd
   ```

## Prebuilt VMDK workflow

1. Build VMDK image:
   ```bash
   nix build .#quantumsec-vmware
   ```
2. Use the VMDK from `result/*.vmdk` (path may vary by nixpkgs revision).
3. Create/import VMware VM from the VMDK.
4. Boot and run:
   ```bash
   hostnamectl
   systemctl status vmtoolsd
   nix run .#host-hardening-audit
   ```

## Security notes for VMware

- SSH remains key-only (`PasswordAuthentication no`, `PermitRootLogin no`).
- Firewall is enabled by default.
- VMware guest support is applied through `nix/modules/vmware.nix`.
- Keep `users.mutableUsers = true` only until initial key provisioning is complete.
