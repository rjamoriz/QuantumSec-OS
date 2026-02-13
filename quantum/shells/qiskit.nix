{ pkgs }:
let
  pyPkgs = pkgs.python311Packages;
  hasQiskit = builtins.hasAttr "qiskit" pyPkgs
    && (builtins.tryEval pyPkgs.qiskit.drvPath).success;
  qiskitPkgs = if hasQiskit then [ pyPkgs.qiskit ] else [ ];

  pythonEnv = pkgs.python311.withPackages (ps:
    with ps;
    [
      ipython
      jupyterlab
      matplotlib
      numpy
      scipy
    ]
    ++ qiskitPkgs);
in
pkgs.mkShell {
  name = "qiskit-shell";
  packages = [ pythonEnv pkgs.git pkgs.ruff ];

  shellHook = ''
    echo "[qiskit] shell ready"
    ${if hasQiskit then "" else "echo \"[qiskit] qiskit unavailable or incompatible in current nixpkgs snapshot\""}
  '';
}
