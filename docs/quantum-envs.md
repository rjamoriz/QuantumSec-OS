# Quantum Development Environments

Quantum Python dependencies are isolated in Nix dev shells. They are not installed into the base OS profile.
These shells are defined for `x86_64-linux` in v1.

## Main shell

```bash
nix develop .#quantum-lab
```

`quantum-lab` includes:
- Python 3.11
- JupyterLab
- `numpy`, `scipy`, `matplotlib`, `networkx`
- `cvxpy` (optimizer)
- Qiskit/PennyLane/Cirq when available in the pinned nixpkgs snapshot

## Framework shells

```bash
nix develop .#qiskit
nix develop .#pennylane
nix develop .#cirq
```

- `qiskit`: includes `qiskit` and `qiskit-aer` when available
- `pennylane`: includes PennyLane when available
- `cirq`: optional shell for Cirq experiments

## Run the example

```bash
nix develop .#quantum-lab -c python quantum/examples/tiny_optimization_demo.py
```

## Smoke test

```bash
./tests/smoke_quantum.sh
```

The smoke test validates core imports and runs the tiny optimization demo.
