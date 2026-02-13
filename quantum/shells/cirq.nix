{ pkgs }:
let
  pyPkgs = pkgs.python312Packages;
  hasCirq = builtins.hasAttr "cirq" pyPkgs;
  cirqPkgs = if hasCirq then [ pyPkgs.cirq ] else [ ];

  pythonEnv = pkgs.python312.withPackages (ps:
    with ps;
    [
      ipython
      numpy
      scipy
    ]
    ++ cirqPkgs);
in
pkgs.mkShell {
  name = "cirq-shell";
  packages = [ pythonEnv pkgs.git ];

  shellHook = ''
    echo "[cirq] shell ready"
    ${if hasCirq then "" else "echo \"[cirq] cirq missing from nixpkgs snapshot\""}
  '';
}
