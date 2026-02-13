{ pkgs }:
let
  pyPkgs = pkgs.python312Packages;
  hasPytket = builtins.hasAttr "pytket" pyPkgs;
  pytketPkgs = if hasPytket then [ pyPkgs.pytket ] else [ ];

  pythonEnv = pkgs.python312.withPackages (ps:
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
    ${if hasPytket then "" else "echo \"[pytket] pytket missing from nixpkgs snapshot\""}
  '';
}
