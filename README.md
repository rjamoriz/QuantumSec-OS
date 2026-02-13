# QuantumSec OS

QuantumSec OS is a flake-based NixOS repository for a reproducible, security-hardened quantum optimization workstation.

## Goals

- Secure-by-default NixOS baseline for desktop and headless use
- Reproducible quantum research dev environments without polluting system profiles
- Build targets for installer ISO and VMware (VMDK) image

## Quickstart (x86_64-linux)

```bash
# Generate/update lock file on a Linux host with Nix installed
nix flake lock

# Run checks
nix flake check

# Build images
nix build .#quantumsec-iso
nix build .#quantumsec-vmware

# Evaluate Linux target derivations
./tests/eval_linux_targets.sh
nix run .#eval-linux-targets

# Generate security summaries from evaluated host configs
nix build .#quantumsec-security-summary-headless
nix build .#quantumsec-security-summary-desktop

# Enter the unified lab shell and run the tiny demo
nix develop .#quantum-lab -c python quantum/examples/tiny_optimization_demo.py

# Run the smoke test through flake app
nix run .#smoke-quantum
```

## Supported targets

- `x86_64-linux`

## Layout

- `flake.nix`: flake outputs for hosts, images, dev shells, checks
- `nix/hosts`: host entry points
- `nix/modules`: reusable security/desktop/headless/quantum modules
- `quantum/shells`: isolated quantum development shells
- `quantum/examples`: tiny offline-friendly demos
- `docs/`: threat model, hardening rationale, build/run docs
- `tests/`: lightweight smoke checks
