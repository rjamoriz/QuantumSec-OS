# Build and Test

All commands below are for a Linux machine with Nix (flakes enabled).

## 1) Lock dependencies

```bash
nix flake lock
```

## 2) Run checks

```bash
nix flake check
```

Checks cover:

- Nix formatting (`alejandra --check`)
- Dev shell evaluation
- NixOS configuration evaluation
- Quantum smoke script execution

## 3) Build installer ISO

```bash
nix build .#quantumsec-iso
```

Result symlink points to the ISO derivation output.

## 4) Build VMware image (VMDK)

```bash
nix build .#quantumsec-vmware
```

Result symlink points to the VMware image derivation output.

## 5) Boot/test guidance

### ISO

1. Write ISO to USB or attach to VM.
2. Boot and confirm networking + SSH hardening defaults.
3. Validate `researcher` account and SSH key configuration before exposure.

### VMware

1. Create VM from built VMDK.
2. Boot and confirm host identity (`hostnamectl`) and firewall state.
3. Run `systemctl status sshd` and `sshd -T | grep -E 'passwordauthentication|permitrootlogin'`.

## macOS note

This repository targets `x86_64-linux` NixOS builds. Build images on Linux for predictable results.
