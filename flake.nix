{
  description = "QuantumSec OS: NixOS distribution for secure quantum workflows in VMware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      linuxSystem = "x86_64-linux";
      hostSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = false;
      };

      pkgsLinux = mkPkgs linuxSystem;

      mkNixos = modules:
        lib.nixosSystem {
          system = linuxSystem;
          specialArgs = {
            inherit self;
          };
          modules = modules;
        };

      isoConfig = mkNixos [ ./nix/iso/installer-iso.nix ];

      vmwareInstalled = mkNixos [
        ./nix/modules/base.nix
        ./nix/modules/security.nix
        ./nix/modules/vmware.nix
        ./nix/modules/quantum.nix
        ./nix/modules/desktop.nix
        ({ ... }: {
          networking.hostName = "quantumsec-vmware";
        })
      ];

      mkIsoOutput = cfg:
        lib.attrByPath [ "system" "build" "images" "iso" ]
          (lib.attrByPath [ "system" "build" "isoImage" ]
            (throw "Missing ISO image output")
            cfg.config)
          cfg.config;

      quantumShells = {
        "quantum-lab" = import ./quantum/shells/default.nix { pkgs = pkgsLinux; };
        qiskit = import ./quantum/shells/qiskit.nix { pkgs = pkgsLinux; };
        pennylane = import ./quantum/shells/pennylane.nix { pkgs = pkgsLinux; };
        cirq = import ./quantum/shells/cirq.nix { pkgs = pkgsLinux; };
      };

      pyPkgs = pkgsLinux.python311Packages;
      hasPy = name:
        builtins.hasAttr name pyPkgs
        && (builtins.tryEval (builtins.getAttr name pyPkgs).drvPath).success;
      optionalPy = name:
        if hasPy name then [ (builtins.getAttr name pyPkgs) ] else [ ];

      smokePython = pkgsLinux.python311.withPackages (ps:
        [
          ps.numpy
          ps.scipy
        ]
        ++ optionalPy "qiskit"
        ++ optionalPy "qiskit-aer");

      mkEvalChecks = hostSystem:
        let
          hostPkgs = mkPkgs hostSystem;
        in
        {
          "format-nix" = hostPkgs.runCommand "format-nix"
            {
              nativeBuildInputs = [ hostPkgs.alejandra ];
            }
            ''
              cd ${self}
              alejandra --check .
              touch $out
            '';

          "eval-nixos-quantumsec-iso" = hostPkgs.writeText "eval-nixos-quantumsec-iso.drvpath"
            isoConfig.config.system.build.toplevel.drvPath;
          "eval-image-quantumsec-iso" = hostPkgs.writeText "eval-image-quantumsec-iso.drvpath"
            (mkIsoOutput isoConfig).drvPath;

          "eval-shell-quantum-lab" = hostPkgs.writeText "eval-shell-quantum-lab.drvpath"
            quantumShells."quantum-lab".drvPath;
          "eval-shell-qiskit" = hostPkgs.writeText "eval-shell-qiskit.drvpath"
            quantumShells.qiskit.drvPath;
          "eval-shell-pennylane" = hostPkgs.writeText "eval-shell-pennylane.drvpath"
            quantumShells.pennylane.drvPath;
          "eval-shell-cirq" = hostPkgs.writeText "eval-shell-cirq.drvpath"
            quantumShells.cirq.drvPath;
        };

      hostDefaultPackages = lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ]
        (hostSystem:
          let
            hostPkgs = mkPkgs hostSystem;
          in
          {
            default = hostPkgs.writeText "quantumsec-os-${hostSystem}-default.txt" ''
              QuantumSec OS primary target is x86_64-linux.

              Build Linux installer ISO:
                nix build .#quantumsec-iso
            '';
          });
    in
    {
      nixosConfigurations = {
        quantumsec-iso = isoConfig;
        quantumsec-vmware = vmwareInstalled;
      };

      packages = hostDefaultPackages // {
        ${linuxSystem} = {
          quantumsec-iso = mkIsoOutput isoConfig;
          quantumsec-vmware-system = vmwareInstalled.config.system.build.toplevel;
          default = mkIsoOutput isoConfig;
        };
      };

      devShells.${linuxSystem} = quantumShells;

      checks =
        lib.genAttrs hostSystems mkEvalChecks
        // {
          ${linuxSystem} =
            (mkEvalChecks linuxSystem)
            // {
              "smoke-quantum" = pkgsLinux.runCommand "smoke-quantum"
                {
                  nativeBuildInputs = [ pkgsLinux.bash smokePython ];
                }
                ''
                  cd ${self}
                  bash tests/smoke_quantum.sh --ci
                  touch $out
                '';
            };
        };
    };
}
