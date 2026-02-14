{pkgs, ...}: {
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  environment.systemPackages = with pkgs; [
    git
    nixd
    nil
    (writeShellScriptBin "quantumsec-shells" ''
            cat <<'EOF'
      Use isolated, reproducible quantum environments:
        nix develop .#quantum-lab
        nix develop .#qiskit
        nix develop .#pennylane
        nix develop .#cirq

      Run the tiny demo:
        nix develop .#quantum-lab -c python quantum/examples/tiny_optimization_demo.py
      EOF
    '')
  ];
}
