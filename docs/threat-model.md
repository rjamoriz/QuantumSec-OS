# Threat Model (v1)

## Scope

- Single VMware Fusion guest running QuantumSec OS
- Quantum simulator and hybrid optimization workloads
- SDK access to cloud quantum backends (for example IBM/Qiskit Runtime, AWS Braket)

## Assets to protect

- Research code and notebooks
- API credentials/tokens used for cloud quantum services
- Integrity of NixOS configuration and build artifacts

## Security goals

- Keep remote access hardened by default
- Limit default attack surface in the VM
- Prevent dependency drift by using reproducible dev shells
- Separate base OS from experimental Python environments

## Assumptions

- VMware host is reasonably trusted and maintained
- Operator controls flake updates
- Secrets are not committed to this repository

## Main threats

- Brute-force and opportunistic SSH attacks
- Malicious or compromised Python dependencies in research tooling
- Misconfiguration drift after manual host changes
- Credential leakage from notebooks/scripts

## v1 mitigations

- Firewall enabled
- SSH key-only authentication with root login disabled
- Nix sandboxing and restricted trusted users
- Minimal enabled services
- Sysctl hardening for kernel/network surfaces
- Quantum dependencies isolated in `nix develop` shells

## Deferred work (v2+)

- Full disk encryption flow in installer
- Secure boot / measured boot policy
- Optional unattended install profile
- Artifact signing and release provenance
