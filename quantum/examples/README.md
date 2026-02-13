# Quantum Examples

This folder contains tiny offline-friendly examples that run inside the `quantum-lab` shell.

## Run

```bash
nix develop .#quantum-lab -c python quantum/examples/tiny_optimization_demo.py
nix develop .#quantum-lab -c python quantum/examples/qasm_roundtrip_demo.py --allow-missing
```

## What it demonstrates

- 1-qubit rotation circuit objective (`RY(theta)`)
- Classical optimization loop with `scipy.optimize.minimize`
- OpenQASM import/export when Qiskit qasm tooling is available
