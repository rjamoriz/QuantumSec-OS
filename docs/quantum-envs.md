# Quantum Environments

Quantum dependencies are isolated in Nix dev shells; nothing is pip-installed into the system profile.

## Available shells

```bash
nix develop .#quantum-lab
nix develop .#qiskit
nix develop .#pennylane
nix develop .#cirq
nix develop .#pytket
```

If a framework is present but incompatible in the pinned nixpkgs snapshot, the shell excludes it and prints a notice.

`quantum-lab` includes:

- Python 3.11
- JupyterLab
- numpy/scipy/matplotlib/networkx
- cvxpy
- Qiskit/PennyLane and optional Cirq/pytket when available and compatible in the pinned nixpkgs snapshot

## Run example

```bash
nix develop .#quantum-lab -c python quantum/examples/tiny_optimization_demo.py
```

## Smoke test

```bash
./tests/smoke_quantum.sh
```

## Untrusted notebook workflow (rootless containers)

Example:

```bash
podman run --rm -it -p 8888:8888 docker.io/jupyter/scipy-notebook:latest
```

Use containers for untrusted notebooks/tools; keep trusted reproducible work in Nix dev shells.
