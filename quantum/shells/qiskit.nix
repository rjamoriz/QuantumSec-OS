{ pkgs }:
let
  pyPkgs = pkgs.python312Packages;
  hasQiskit = builtins.hasAttr "qiskit" pyPkgs;
  qiskitPkgs = if hasQiskit then [ pyPkgs.qiskit ] else [ ];

  pythonEnv = pkgs.python312.withPackages (ps:
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
    ${if hasQiskit then "" else "echo \"[qiskit] qiskit missing from nixpkgs snapshot\""}
  '';
}
