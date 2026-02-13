#!/usr/bin/env python3
"""OpenQASM roundtrip demo.

Exports a tiny circuit to OpenQASM and re-imports it when qiskit.qasm2 is available.
"""

from __future__ import annotations

import argparse


def run_roundtrip() -> bool:
    try:
        from qiskit import QuantumCircuit, qasm2
    except Exception:
        return False

    circuit = QuantumCircuit(2)
    circuit.h(0)
    circuit.cx(0, 1)

    qasm_text = qasm2.dumps(circuit)
    restored = qasm2.loads(qasm_text)

    return restored.num_qubits == circuit.num_qubits and restored.count_ops() == circuit.count_ops()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--allow-missing",
        action="store_true",
        help="Exit 0 if qiskit/qasm2 is unavailable",
    )
    args = parser.parse_args()

    ok = run_roundtrip()
    if ok:
        print("qasm-roundtrip=ok")
        return 0

    print("qasm-roundtrip=unavailable")
    return 0 if args.allow_missing else 1


if __name__ == "__main__":
    raise SystemExit(main())
