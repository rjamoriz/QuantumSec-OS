# QuantumSec OS

QuantumSec OS is a NixOS-based Linux distribution project for quantum computing workflows, delivered as a bootable installer ISO for VMware Fusion.

## Project goals

- Bootable ISO that installs a persistent QuantumSec VM
- Security-hardened baseline (firewall, hardened SSH, sandboxed Nix builds)
- Reproducible quantum development environments in isolated `nix develop` shells
- Practical VMware guest integration (`open-vm-tools`, VMware guest enablement)

## Supported target

- `x86_64-linux`

## Quickstart

```bash
nix flake lock
nix flake check
nix build .#quantumsec-iso
```

On macOS, `nix build .#quantumsec-iso` produces a guidance artifact.
The real Linux ISO derivation is:

```bash
nix eval --raw .#packages.x86_64-linux.quantumsec-iso.drvPath
nix build .#packages.x86_64-linux.quantumsec-iso
```

## VMware install flow (persistent VM)

1. Build ISO: `nix build .#quantumsec-iso`
2. In VMware Fusion, create a Linux VM in UEFI mode and attach the built ISO.
3. Boot ISO and run `quantumsec-install-guide` in the installer shell.
4. Install to VM disk using the provided command:
   - `nixos-install --root /mnt --flake <repo>#quantumsec-vmware`
5. Reboot into installed system.

Default local login for v1 convenience:
- user: `quantum`
- password: `quantum`

Change the password immediately after first boot.

## Quantum environments

```bash
nix develop .#quantum-lab
nix develop .#qiskit
nix develop .#pennylane
nix develop .#cirq
```

Run the example:

```bash
nix develop .#quantum-lab -c python quantum/examples/tiny_optimization_demo.py
```

## Repository layout

- `flake.nix`
- `flake.lock`
- `AGENTS.md`
- `nix/modules/{base,security,vmware,quantum,desktop}.nix`
- `nix/iso/installer-iso.nix`
- `quantum/examples/`
- `docs/{build,quantum-envs,hardening,threat-model}.md`
- `tests/smoke_quantum.sh`
