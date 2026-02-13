{ pkgs }:
let
  pyPkgs = pkgs.python311Packages;
  hasCirq = builtins.hasAttr "cirq" pyPkgs
    && (builtins.tryEval pyPkgs.cirq.drvPath).success;
  cirqPkgs = if hasCirq then [ pyPkgs.cirq ] else [ ];

  pythonEnv = pkgs.python311.withPackages (ps:
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
    ${if hasCirq then "" else "echo \"[cirq] cirq unavailable or incompatible in current nixpkgs snapshot\""}
  '';
}
