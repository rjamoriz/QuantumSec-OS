#!/usr/bin/env python3
"""Tiny offline quantum optimization demo.

- Uses qiskit if present.
- Falls back to a pure numpy single-qubit model if qiskit is unavailable.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass

import numpy as np
from scipy.optimize import minimize

try:
    from qiskit import QuantumCircuit
    from qiskit.quantum_info import Statevector
except Exception:  # pragma: no cover - optional dependency path
    QuantumCircuit = None
    Statevector = None


@dataclass
class DemoResult:
    theta: float
    cost: float
    qasm_roundtrip_ok: bool


def _cost_with_qiskit(theta: float) -> float:
    qc = QuantumCircuit(1)
    qc.ry(theta, 0)
    state = Statevector.from_instruction(qc)
    probs = state.probabilities()
    return float(probs[1])


def _cost_numpy(theta: float) -> float:
    # Probability of measuring |1> after RY(theta)|0>
    return float(np.sin(theta / 2.0) ** 2)


def _qasm_roundtrip(theta: float) -> bool:
    if QuantumCircuit is None:
        return False

    try:
        from qiskit import qasm2
    except Exception:
        return False

    qc = QuantumCircuit(1)
    qc.ry(theta, 0)

    encoded = qasm2.dumps(qc)
    decoded = qasm2.loads(encoded)
    return decoded.num_qubits == qc.num_qubits


def run_demo() -> DemoResult:
    use_qiskit = QuantumCircuit is not None and Statevector is not None
    objective = _cost_with_qiskit if use_qiskit else _cost_numpy

    result = minimize(lambda x: objective(float(x[0])), x0=np.array([1.0]), method="COBYLA")
    theta = float(result.x[0])
    cost = float(result.fun)
    qasm_ok = _qasm_roundtrip(theta)

    return DemoResult(theta=theta, cost=cost, qasm_roundtrip_ok=qasm_ok)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--smoke", action="store_true", help="Short output for CI/smoke checks")
    args = parser.parse_args()

    demo = run_demo()

    if args.smoke:
        print(f"theta={demo.theta:.6f} cost={demo.cost:.6e} qasm_roundtrip={demo.qasm_roundtrip_ok}")
        return 0

    print("QuantumSec tiny optimization demo")
    print(f"best theta: {demo.theta:.6f}")
    print(f"best cost : {demo.cost:.6e}")
    print(f"QASM import/export available: {demo.qasm_roundtrip_ok}")
    print("expected optimum: theta ~= 0 mod 2*pi")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
