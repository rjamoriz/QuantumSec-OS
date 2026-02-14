# Design Overview

This document explains the architecture and design decisions of QuantumSec OS.

## Primary intent

QuantumSec OS is a NixOS flake project for a security-hardened quantum development workstation that can be run in VMware.

Your target execution paths in VMware are now explicit:

- `quantumsec-vmware-iso`: VMware-oriented installer ISO
- `quantumsec-vmware`: prebuilt VMware VMDK image

## Artifact model

Flake package outputs (`x86_64-linux`):

- `quantumsec-iso`: general installer ISO
- `quantumsec-vmware-iso`: installer ISO with VMware guest profile enabled
- `quantumsec-vmware`: VMware image derivation (VMDK path)
- `quantumsec-desktop`: desktop host system closure
- `quantumsec-headless`: headless host system closure
- `quantumsec-security-summary-headless` / `quantumsec-security-summary-desktop` / `quantumsec-security-summary-vmware`: evaluated security baselines

## Host design

- `quantumsec-headless`
  - no GUI
  - SSH + security baseline + quantum tooling
  - intended for server-like research nodes and CI-style execution

- `quantumsec-desktop`
  - Wayland-first
  - Hyprland enabled, Sway fallback
  - intended for interactive workstation workflows

## ISO and VMware strategy

- Installer workflow (recommended when you want installation control):
  1. Build `quantumsec-vmware-iso`
  2. Attach ISO to a VMware VM with a blank virtual disk
  3. Install and provision keys
  4. Run host audit (`nix run .#host-hardening-audit`)

- Prebuilt image workflow (recommended for fast bring-up):
  1. Build `quantumsec-vmware`
  2. Import resulting VMDK into VMware
  3. Boot and run host audit

Both VMware outputs share `nix/modules/vmware.nix`, which keeps VMware guest support explicit and includes VMware storage/network initrd modules for predictable early boot in VMware guests.

## Security architecture

Layered controls in `nix/modules/security.nix`:

- network baseline: firewall on, conservative defaults
- SSH hardening: key-only login, root SSH disabled
- Nix hardening: sandbox enabled, restricted trusted users
- kernel/sysctl hardening for common local attack surface reduction
- hardened custom systemd service for baseline reporting
- periodic timer-based refresh (`quantumsec-baseline-report.timer`)

Policy is enforced at evaluation time via flake checks:

- `checks.x86_64-linux.policy-headless`
- `checks.x86_64-linux.policy-desktop`
- `checks.x86_64-linux.policy-vmware`

These fail when critical baseline expectations regress.

## Quantum development architecture

- Reproducible dev shells under `quantum/shells/`
- Unified shell: `quantum-lab`
- Optional framework inclusion uses compatibility checks (frameworks are included only when available and evaluable in pinned nixpkgs)
- Examples under `quantum/examples/` are offline-friendly and short-running

## Operational tooling

- `nix run .#scan-secrets`: repository secret-pattern scan
- `nix run .#eval-linux-targets`: verify Linux target derivations
- `nix run .#show-vmware-artifacts`: print evaluated VMware ISO/VMDK paths
- `nix run .#build-linux-artifacts`: run checks + build Linux artifacts
- `nix run .#show-security-summary -- headless|desktop|vmware`: print evaluated baseline summary
- `nix run .#host-hardening-audit`: post-boot host audit

## Current tradeoffs

- Shell framework availability depends on pinned nixpkgs compatibility; unsupported frameworks are skipped gracefully.
- Full Linux artifact builds should be performed on Linux hosts for predictable results.
- macOS is treated as an operator/development host, not a target runtime.

## Near-term roadmap

1. Add VM provisioning docs with concrete VMware VMX/UEFI settings.
2. Add NixOS test(s) for SSH hardening and timer activation.
3. Add optional signed artifact release flow for ISO/VMDK outputs.
