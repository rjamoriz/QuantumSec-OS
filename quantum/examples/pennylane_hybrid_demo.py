#!/usr/bin/env python3
"""Tiny PennyLane hybrid optimization demo.

Runs a 1-qubit variational loop when PennyLane is available.
"""

from __future__ import annotations

import argparse


def run_demo() -> tuple[float, float] | None:
    try:
        import pennylane as qml
    except Exception:
        return None

    np = qml.numpy
    device = qml.device("default.qubit", wires=1)

    @qml.qnode(device)
    def circuit(theta):
        qml.RY(theta, wires=0)
        return qml.expval(qml.PauliZ(0))

    def cost(theta):
        # Minimize distance to expectation value -1.
        return (circuit(theta) + 1.0) ** 2

    theta = np.array(0.3, requires_grad=True)
    opt = qml.GradientDescentOptimizer(stepsize=0.25)

    for _ in range(25):
        theta = opt.step(cost, theta)

    final_theta = float(theta)
    final_cost = float(cost(theta))
    return final_theta, final_cost


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--allow-missing", action="store_true", help="Exit 0 if PennyLane is unavailable")
    parser.add_argument("--smoke", action="store_true", help="Short output for smoke checks")
    args = parser.parse_args()

    result = run_demo()
    if result is None:
        print("pennylane-hybrid=unavailable")
        return 0 if args.allow_missing else 1

    theta, loss = result

    if args.smoke:
        print(f"pennylane-theta={theta:.6f} pennylane-loss={loss:.6e}")
        return 0

    print("PennyLane hybrid optimization demo")
    print(f"final theta: {theta:.6f}")
    print(f"final loss : {loss:.6e}")
    print("target is expectation value near -1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
