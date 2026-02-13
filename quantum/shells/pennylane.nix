{ pkgs }:
let
  pyPkgs = pkgs.python311Packages;
  hasPennyLane = builtins.hasAttr "pennylane" pyPkgs
    && (builtins.tryEval pyPkgs.pennylane.drvPath).success;
  pennyPkgs = if hasPennyLane then [ pyPkgs.pennylane ] else [ ];

  pythonEnv = pkgs.python311.withPackages (ps:
    with ps;
    [
      cvxpy
      ipython
      jupyterlab
      matplotlib
      numpy
      scipy
    ]
    ++ pennyPkgs);
in
pkgs.mkShell {
  name = "pennylane-shell";
  packages = [ pythonEnv pkgs.git pkgs.ruff ];

  shellHook = ''
    echo "[pennylane] shell ready"
    ${if hasPennyLane then "" else "echo \"[pennylane] pennylane unavailable or incompatible in current nixpkgs snapshot\""}
  '';
}
