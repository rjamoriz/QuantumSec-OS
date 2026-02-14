{
  description = "QuantumSec OS: NixOS distribution for secure quantum workflows in VMware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    lib = nixpkgs.lib;
    linuxSystem = "x86_64-linux";

    mkPkgs = system:
      import nixpkgs {
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

    isoConfig = mkNixos [./nix/iso/installer-iso.nix];

    vmwareInstalled = mkNixos [
      ./nix/modules/base.nix
      ./nix/modules/security.nix
      ./nix/modules/vmware.nix
      ./nix/modules/quantum.nix
      ./nix/modules/desktop.nix
      ({lib, ...}: {
        networking.hostName = "quantumsec-vmware";
        fileSystems."/" = lib.mkDefault {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        boot.loader.grub = {
          enable = lib.mkDefault true;
          device = lib.mkDefault "/dev/sda";
        };
      })
    ];

    mkIsoOutput = cfg:
      lib.attrByPath ["system" "build" "images" "iso"]
      (lib.attrByPath ["system" "build" "isoImage"]
        (throw "Missing ISO image output")
        cfg.config)
      cfg.config;

    mkQuantumShells = system: let
      shellPkgs = mkPkgs system;
    in {
      "quantum-lab" = import ./quantum/shells/default.nix {pkgs = shellPkgs;};
      qiskit = import ./quantum/shells/qiskit.nix {pkgs = shellPkgs;};
      pennylane = import ./quantum/shells/pennylane.nix {pkgs = shellPkgs;};
      cirq = import ./quantum/shells/cirq.nix {pkgs = shellPkgs;};
    };

    linuxQuantumShells = mkQuantumShells linuxSystem;

    mkEvalChecks = hostSystem: let
      hostPkgs = mkPkgs hostSystem;
    in {
      "format-nix" =
        hostPkgs.runCommand "format-nix"
        {
          nativeBuildInputs = [hostPkgs.alejandra];
        }
        ''
          cd ${self}
          alejandra --check .
          touch $out
        '';

      "eval-nixos-quantumsec-iso" =
        hostPkgs.writeText "eval-nixos-quantumsec-iso.drvpath"
        ''
          hostName=${isoConfig.config.networking.hostName}
          stateVersion=${isoConfig.config.system.stateVersion}
        '';
      "eval-image-quantumsec-iso" =
        hostPkgs.writeText "eval-image-quantumsec-iso.drvpath"
        "type=${builtins.typeOf (mkIsoOutput isoConfig)}";

      "eval-shell-quantum-lab" =
        hostPkgs.writeText "eval-shell-quantum-lab.drvpath"
        "type=${builtins.typeOf linuxQuantumShells."quantum-lab"}";
      "eval-shell-qiskit" =
        hostPkgs.writeText "eval-shell-qiskit.drvpath"
        "type=${builtins.typeOf linuxQuantumShells.qiskit}";
      "eval-shell-pennylane" =
        hostPkgs.writeText "eval-shell-pennylane.drvpath"
        "type=${builtins.typeOf linuxQuantumShells.pennylane}";
      "eval-shell-cirq" =
        hostPkgs.writeText "eval-shell-cirq.drvpath"
        "type=${builtins.typeOf linuxQuantumShells.cirq}";
    };

    hostDefaultPackages =
      lib.genAttrs ["x86_64-darwin" "aarch64-darwin"]
      (hostSystem: let
        hostPkgs = mkPkgs hostSystem;
      in {
        default = hostPkgs.writeText "quantumsec-os-${hostSystem}-default.txt" ''
          QuantumSec OS primary target is x86_64-linux.

          Build Linux installer ISO:
            nix build .#quantumsec-iso
            nix build .#packages.x86_64-linux.quantumsec-iso
        '';
        quantumsec-iso = hostPkgs.writeText "quantumsec-os-${hostSystem}-quantumsec-iso.txt" ''
          This host is ${hostSystem}. The real ISO artifact is Linux-only:
            nix build .#packages.x86_64-linux.quantumsec-iso
        '';
      });
  in {
    nixosConfigurations = {
      quantumsec-iso = isoConfig;
      quantumsec-vmware = vmwareInstalled;
    };

    packages =
      hostDefaultPackages
      // {
        ${linuxSystem} = {
          quantumsec-iso = mkIsoOutput isoConfig;
          quantumsec-vmware-system = vmwareInstalled.config.system.build.toplevel;
          default = mkIsoOutput isoConfig;
        };
      };

    devShells = lib.genAttrs [linuxSystem "x86_64-darwin" "aarch64-darwin"] mkQuantumShells;

    checks = {
      x86_64-darwin = mkEvalChecks "x86_64-darwin";
      aarch64-darwin = mkEvalChecks "aarch64-darwin";
    };
  };
}
