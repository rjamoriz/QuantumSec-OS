{
  description = "QuantumSec OS: secure NixOS baseline for quantum optimization research";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";

      mkNixos = modules:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self;
          };
          modules = modules;
        };

      headless = mkNixos [ ./nix/hosts/quantumsec-headless.nix ];

      mkImageOutput = cfg: imageName: fallbackName:
        lib.attrByPath [ "system" "build" "images" imageName ]
          (lib.attrByPath [ "system" "build" fallbackName ]
            (throw "Missing image output ${imageName}/${fallbackName}"))
          cfg.config;

      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      nixosConfigurations.quantumsec-headless = headless;

      packages.${system} = {
        quantumsec-iso = mkImageOutput headless "iso" "isoImage";
        quantumsec-vmware = mkImageOutput headless "vmware" "vmwareImage";
      };

      checks.${system} = {
        eval-headless = pkgs.writeText "eval-headless.drvpath"
          headless.config.system.build.toplevel.drvPath;
      };
    };
}
