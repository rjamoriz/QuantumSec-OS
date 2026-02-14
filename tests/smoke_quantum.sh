#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" != "--ci" ]]; then
  if ! command -v nix >/dev/null 2>&1; then
    echo "nix is required to run this smoke test"
    exit 1
  fi

  nix develop "${REPO_ROOT}#quantum-lab" -c python -c "import numpy, scipy; print('ok')"
  nix develop "${REPO_ROOT}#quantum-lab" -c python "${REPO_ROOT}/quantum/examples/tiny_optimization_demo.py" --smoke
  echo "smoke-quantum=ok"
  exit 0
fi

cd "${REPO_ROOT}"

python quantum/examples/tiny_optimization_demo.py --smoke
python - <<'PY'
import importlib

required = ["numpy", "scipy"]
for module in required:
    importlib.import_module(module)

print("ok")
PY

echo "smoke-quantum=ok"
