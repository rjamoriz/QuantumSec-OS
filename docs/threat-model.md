# Threat Model (Initial v1)

## Scope

- Single-user research workstation running NixOS
- Quantum optimization experimentation, notebooks, and simulations
- Build/release artifacts: installer ISO and VMware image

## Security objectives

- Preserve integrity of OS configuration and research code
- Reduce attack surface of remote access and default services
- Isolate untrusted research workloads from host baseline

## Assets

- Source code and experiment notebooks
- SSH keys and operator credentials
- Reproducible Nix configurations and build outputs

## Assumptions

- Trusted operator controls flake updates
- Host firmware and hardware are outside v1 scope
- No secrets are stored directly in this repository

## Adversaries

- Opportunistic internet scanning/brute force attempts on SSH
- Malicious notebook/tool dependencies run by researcher
- Accidental insecure local configuration drift

## Initial mitigations

- Firewall enabled by default
- SSH key-only auth, password auth disabled, root SSH disabled
- Minimal default services
- Hardened kernel/sysctl baseline
- Rootless Podman workflow for untrusted research tooling

## Deferred items

- Secure boot / TPM measured boot policy
- Full disk encryption installer flow
- Centralized audit log pipeline and SIEM integration
