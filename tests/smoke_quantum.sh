#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" != "--ci" ]]; then
  if command -v nix >/dev/null 2>&1; then
    NIX_BIN="$(command -v nix)"
  elif [[ -x "/nix/var/nix/profiles/default/bin/nix" ]]; then
    NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
  else
    echo "nix is required to run this smoke test"
    exit 1
  fi

  NIX=("$NIX_BIN" --extra-experimental-features "nix-command flakes")

  "${NIX[@]}" develop "${REPO_ROOT}#quantum-lab" -c python -c "import numpy, scipy; print('ok')"
  "${NIX[@]}" develop "${REPO_ROOT}#quantum-lab" -c python "${REPO_ROOT}/quantum/examples/tiny_optimization_demo.py" --smoke
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
