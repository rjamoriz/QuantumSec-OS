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
nix develop .#quantum-lab -c python quantum/examples/qasm_roundtrip_demo.py --allow-missing
nix develop .#quantum-lab -c python quantum/examples/pennylane_hybrid_demo.py --allow-missing
```

## Smoke test

```bash
./tests/smoke_quantum.sh
# or via app output (x86_64-linux)
nix run .#smoke-quantum
```

## Untrusted notebook workflow (rootless containers)

Example:

```bash
nix run .#run-untrusted-notebook
# or directly
./quantum/sandbox/run_untrusted_notebook.sh
```

Use containers for untrusted notebooks/tools; keep trusted reproducible work in Nix dev shells.

Environment knobs for the sandbox script:

- `NOTEBOOK_PORT` (default `8888`)
- `NOTEBOOK_TOKEN` (default `quantumsec`)
- `NOTEBOOK_WORKDIR` (default current directory)
