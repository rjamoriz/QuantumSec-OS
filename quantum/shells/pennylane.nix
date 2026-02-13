{ pkgs }:
let
  pyPkgs = pkgs.python312Packages;
  hasPennyLane = builtins.hasAttr "pennylane" pyPkgs;
  pennyPkgs = if hasPennyLane then [ pyPkgs.pennylane ] else [ ];

  pythonEnv = pkgs.python312.withPackages (ps:
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
    ${if hasPennyLane then "" else "echo \"[pennylane] pennylane missing from nixpkgs snapshot\""}
  '';
}
