#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" != "--ci" ]]; then
  if ! command -v nix >/dev/null 2>&1; then
    echo "nix is required to run this smoke test"
    exit 1
  fi

  exec nix develop "${REPO_ROOT}#quantum-lab" -c "${BASH_SOURCE[0]}" --ci
fi

cd "${REPO_ROOT}"

python quantum/examples/tiny_optimization_demo.py --smoke
python quantum/examples/qasm_roundtrip_demo.py --allow-missing
python quantum/examples/pennylane_hybrid_demo.py --allow-missing --smoke
python - <<'PY'
import importlib

required = ["numpy", "scipy", "matplotlib", "networkx"]
for module in required:
    importlib.import_module(module)

print("core-python-imports=ok")
PY

echo "smoke-quantum=ok"
