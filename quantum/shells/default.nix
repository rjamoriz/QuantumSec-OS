{ pkgs }:
let
  pyPkgs = pkgs.python312Packages;
  has = name: builtins.hasAttr name pyPkgs;
  get = name: builtins.getAttr name pyPkgs;
  optional = name: if has name then [ (get name) ] else [ ];

  desired = [ "qiskit" "pennylane" "cirq" "pytket" ];
  present = builtins.filter has desired;
  missing = builtins.filter (name: !(has name)) desired;

  presentText =
    if present == [ ] then "none"
    else builtins.concatStringsSep ", " present;

  missingText =
    if missing == [ ] then ""
    else builtins.concatStringsSep ", " missing;

  pythonEnv = pkgs.python312.withPackages (ps:
    with ps;
    [
      cvxpy
      ipython
      jupyterlab
      matplotlib
      networkx
      numpy
      pip
      scipy
    ]
    ++ optional "qiskit"
    ++ optional "pennylane"
    ++ optional "cirq"
    ++ optional "pytket");
in
pkgs.mkShell {
  name = "quantum-lab";

  packages = [
    pythonEnv
    pkgs.alejandra
    pkgs.git
    pkgs.nil
    pkgs.ruff
  ];

  shellHook = ''
    echo "[quantum-lab] available quantum frameworks: ${presentText}"
    ${if missing == [ ]
      then ""
      else "echo \"[quantum-lab] unavailable in current nixpkgs snapshot: ${missingText}\""}
    echo "[quantum-lab] run: python quantum/examples/tiny_optimization_demo.py"
  '';
}
