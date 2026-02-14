{pkgs}: let
  pyPkgs = pkgs.python311Packages;
  hasAttr = name: builtins.hasAttr name pyPkgs;
  get = name: builtins.getAttr name pyPkgs;
  isUsable = name: hasAttr name && (builtins.tryEval (get name).drvPath).success;
  optional = name:
    if isUsable name
    then [(get name)]
    else [];
  hasQiskit = isUsable "qiskit";
  hasQiskitAer = isUsable "qiskit-aer";

  pythonEnv = pkgs.python311.withPackages (ps:
    with ps;
      [
        ipython
        jupyterlab
        matplotlib
        numpy
        scipy
      ]
      ++ optional "qiskit"
      ++ optional "qiskit-aer");
in
  pkgs.mkShell {
    name = "qiskit-shell";
    packages = [pythonEnv pkgs.git];

    shellHook = ''
      echo "[qiskit] shell ready"
      ${
        if hasQiskit
        then ""
        else "echo \"[qiskit] qiskit unavailable or incompatible in current nixpkgs snapshot\""
      }
      ${
        if hasQiskitAer
        then ""
        else "echo \"[qiskit] qiskit-aer unavailable or incompatible in current nixpkgs snapshot\""
      }
    '';
  }
