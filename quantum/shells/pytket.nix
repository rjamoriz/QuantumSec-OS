{ pkgs }:
let
  pyPkgs = pkgs.python311Packages;
  hasPytket = builtins.hasAttr "pytket" pyPkgs
    && (builtins.tryEval pyPkgs.pytket.drvPath).success;
  pytketPkgs = if hasPytket then [ pyPkgs.pytket ] else [ ];

  pythonEnv = pkgs.python311.withPackages (ps:
    with ps;
    [
      ipython
      numpy
      scipy
    ]
    ++ pytketPkgs);
in
pkgs.mkShell {
  name = "pytket-shell";
  packages = [ pythonEnv pkgs.git ];

  shellHook = ''
    echo "[pytket] shell ready"
    ${if hasPytket then "" else "echo \"[pytket] pytket unavailable or incompatible in current nixpkgs snapshot\""}
  '';
}
