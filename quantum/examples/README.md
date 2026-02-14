# Quantum Examples

This folder contains tiny offline-friendly examples that run inside the `quantum-lab` shell.

## Run

```bash
nix develop .#quantum-lab -c python quantum/examples/tiny_optimization_demo.py
```

## What it demonstrates

- 1-qubit rotation circuit objective (`RY(theta)`)
- Classical optimization loop with `scipy.optimize.minimize`
- Qiskit simulation path when Qiskit is available
- Numpy fallback path when Qiskit is unavailable
