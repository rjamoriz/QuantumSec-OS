{
  description = "QuantumSec OS: secure NixOS baseline for quantum optimization research";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      linuxSystem = "x86_64-linux";
      lib = nixpkgs.lib;

      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = false;
      };

      pkgs = mkPkgs linuxSystem;

      mkNixos = modules:
        lib.nixosSystem {
          system = linuxSystem;
          specialArgs = {
            inherit self;
          };
          modules = modules;
        };

      mkImageOutput = cfg: imageName: fallbackName:
        lib.attrByPath [ "system" "build" "images" imageName ]
          (lib.attrByPath [ "system" "build" fallbackName ]
            (throw "Missing image output ${imageName}/${fallbackName}"))
          cfg.config;

      headless = mkNixos [ ./nix/hosts/quantumsec-headless.nix ];
      desktop = mkNixos [ ./nix/hosts/quantumsec-desktop.nix ];

      isoConfig = mkNixos [
        ./nix/hosts/quantumsec-desktop.nix
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ({ lib, ... }: {
          networking.hostName = lib.mkForce "quantumsec-installer";
          users.users.researcher.hashedPassword = lib.mkForce "!";
        })
      ];

      vmwareConfig = mkNixos [
        ./nix/hosts/quantumsec-headless.nix
        "${nixpkgs}/nixos/modules/virtualisation/vmware-image.nix"
        ({ lib, ... }: {
          networking.hostName = lib.mkForce "quantumsec-vmware";
          users.users.researcher.hashedPassword = lib.mkForce "!";
        })
      ];

      quantumShells = {
        "quantum-lab" = import ./quantum/shells/default.nix { inherit pkgs; };
        qiskit = import ./quantum/shells/qiskit.nix { inherit pkgs; };
        pennylane = import ./quantum/shells/pennylane.nix { inherit pkgs; };
        cirq = import ./quantum/shells/cirq.nix { inherit pkgs; };
        pytket = import ./quantum/shells/pytket.nix { inherit pkgs; };
      };

      pyPkgs = pkgs.python312Packages;
      hasPy = name: builtins.hasAttr name pyPkgs;
      getPy = name: builtins.getAttr name pyPkgs;
      optionalPy = name: if hasPy name then [ (getPy name) ] else [ ];

      smokePython = pkgs.python312.withPackages (_:
        [
          pyPkgs.cvxpy
          pyPkgs.matplotlib
          pyPkgs.networkx
          pyPkgs.numpy
          pyPkgs.scipy
        ]
        ++ optionalPy "qiskit"
        ++ optionalPy "pennylane");

      hostDefaultPackages = lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ]
        (hostSystem:
          let
            hostPkgs = mkPkgs hostSystem;
          in
          {
            default = hostPkgs.writeText "quantumsec-os-${hostSystem}-default.txt" ''
              QuantumSec OS default output for ${hostSystem}

              Primary supported build target: x86_64-linux
              Build explicit artifacts:
                nix build .#quantumsec-iso
                nix build .#quantumsec-vmware
            '';
          });
    in
    {
      nixosConfigurations = {
        quantumsec-desktop = desktop;
        quantumsec-headless = headless;
      };

      packages = hostDefaultPackages // {
        ${linuxSystem} = {
          "quantumsec-iso" = mkImageOutput isoConfig "iso" "isoImage";
          "quantumsec-vmware" = mkImageOutput vmwareConfig "vmware" "vmwareImage";
          default = mkImageOutput isoConfig "iso" "isoImage";
        };
      };

      devShells.${linuxSystem} = quantumShells;

      checks.${linuxSystem} = {
        "format-nix" = pkgs.runCommand "format-nix" { nativeBuildInputs = [ pkgs.alejandra ]; } ''
          cd ${self}
          alejandra --check .
          touch $out
        '';

        "eval-shell-quantum-lab" = pkgs.writeText "eval-shell-quantum-lab.drvpath"
          quantumShells."quantum-lab".drvPath;
        "eval-shell-qiskit" = pkgs.writeText "eval-shell-qiskit.drvpath"
          quantumShells.qiskit.drvPath;
        "eval-shell-pennylane" = pkgs.writeText "eval-shell-pennylane.drvpath"
          quantumShells.pennylane.drvPath;

        "eval-nixos-headless" = pkgs.writeText "eval-nixos-headless.drvpath"
          headless.config.system.build.toplevel.drvPath;
        "eval-nixos-desktop" = pkgs.writeText "eval-nixos-desktop.drvpath"
          desktop.config.system.build.toplevel.drvPath;

        "smoke-quantum" = pkgs.runCommand "smoke-quantum"
          {
            nativeBuildInputs = [ pkgs.bash smokePython ];
          }
          ''
            cd ${self}
            bash tests/smoke_quantum.sh --ci
            touch $out
          '';
      };
    };
}
