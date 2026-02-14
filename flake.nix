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
            (throw "Missing image output ${imageName}/${fallbackName}")
            cfg.config)
          cfg.config;

      headless = mkNixos [ ./nix/hosts/quantumsec-headless.nix ];
      desktop = mkNixos [ ./nix/hosts/quantumsec-desktop.nix ];

      isoConfig = mkNixos [
        ./nix/hosts/quantumsec-desktop.nix
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ({ lib, ... }: {
          networking.hostName = lib.mkForce "quantumsec-installer";
          networking.wireless.enable = lib.mkForce false;
          users.users.researcher.hashedPassword = lib.mkForce "!";
          services.openssh.settings.PermitRootLogin = lib.mkForce "no";
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

      mkSecurityPolicyCheck = name: cfg:
        let
          c = cfg.config;
          ssh = c.services.openssh.settings;
          reportSvc = c.systemd.services.quantumsec-baseline-report.serviceConfig;
          reportTimer = c.systemd.timers.quantumsec-baseline-report.timerConfig;
        in
        assert c.networking.firewall.enable;
        assert ssh.PasswordAuthentication == false;
        assert ssh.KbdInteractiveAuthentication == false;
        assert ssh.PermitRootLogin == "no";
        assert c.nix.settings.sandbox == true;
        assert c.virtualisation.podman.enable;
        assert c.virtualisation.podman.dockerCompat == false;
        assert c.boot.kernel.sysctl."kernel.kptr_restrict" == 2;
        assert c.boot.kernel.sysctl."kernel.dmesg_restrict" == 1;
        assert c.boot.kernel.sysctl."kernel.unprivileged_bpf_disabled" == 1;
        assert reportSvc.NoNewPrivileges == true;
        assert reportSvc.PrivateTmp == true;
        assert reportSvc.ProtectSystem == "strict";
        assert reportSvc.ProtectHome == true;
        assert reportTimer.Persistent == true;
        assert reportTimer.OnUnitActiveSec == "24h";
        pkgs.writeText "policy-${name}.txt" ''
          security-policy=${name}:ok
        '';

      boolText = b: if b then "true" else "false";

      mkSecuritySummary = name: cfg:
        let
          c = cfg.config;
          ssh = c.services.openssh.settings;
          reportSvc = c.systemd.services.quantumsec-baseline-report.serviceConfig;
          reportTimer = c.systemd.timers.quantumsec-baseline-report.timerConfig;
        in
        pkgs.writeText "security-summary-${name}.txt" ''
          host=${name}
          firewall.enabled=${boolText c.networking.firewall.enable}
          firewall.allowPing=${boolText c.networking.firewall.allowPing}
          ssh.passwordAuthentication=${boolText ssh.PasswordAuthentication}
          ssh.kbdInteractiveAuthentication=${boolText ssh.KbdInteractiveAuthentication}
          ssh.permitRootLogin=${ssh.PermitRootLogin}
          nix.sandbox=${boolText c.nix.settings.sandbox}
          podman.enable=${boolText c.virtualisation.podman.enable}
          podman.dockerCompat=${boolText c.virtualisation.podman.dockerCompat}
          sysctl.kernel.kptr_restrict=${toString c.boot.kernel.sysctl."kernel.kptr_restrict"}
          sysctl.kernel.dmesg_restrict=${toString c.boot.kernel.sysctl."kernel.dmesg_restrict"}
          sysctl.kernel.unprivileged_bpf_disabled=${toString c.boot.kernel.sysctl."kernel.unprivileged_bpf_disabled"}
          service.quantumsec-baseline-report.NoNewPrivileges=${boolText reportSvc.NoNewPrivileges}
          service.quantumsec-baseline-report.PrivateTmp=${boolText reportSvc.PrivateTmp}
          service.quantumsec-baseline-report.ProtectSystem=${reportSvc.ProtectSystem}
          service.quantumsec-baseline-report.ProtectHome=${boolText reportSvc.ProtectHome}
          timer.quantumsec-baseline-report.OnUnitActiveSec=${reportTimer.OnUnitActiveSec}
          timer.quantumsec-baseline-report.Persistent=${boolText reportTimer.Persistent}
        '';

      quantumShells = {
        "quantum-lab" = import ./quantum/shells/default.nix { inherit pkgs; };
        qiskit = import ./quantum/shells/qiskit.nix { inherit pkgs; };
        pennylane = import ./quantum/shells/pennylane.nix { inherit pkgs; };
        cirq = import ./quantum/shells/cirq.nix { inherit pkgs; };
        pytket = import ./quantum/shells/pytket.nix { inherit pkgs; };
      };

      pyPkgs = pkgs.python311Packages;
      hasPy = name: builtins.hasAttr name pyPkgs;
      getPy = name: builtins.getAttr name pyPkgs;
      isUsablePy = name: hasPy name && (builtins.tryEval (getPy name).drvPath).success;
      optionalPy = name: if isUsablePy name then [ (getPy name) ] else [ ];

      smokePython = pkgs.python311.withPackages (_:
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

      mkEvalTargetsApp = hostSystem:
        let
          hostPkgs = mkPkgs hostSystem;
          app = hostPkgs.writeShellApplication {
            name = "eval-linux-targets";
            text = ''
              exec "${self}/tests/eval_linux_targets.sh" "$@"
            '';
          };
        in
        {
          eval-linux-targets = {
            type = "app";
            program = "${app}/bin/eval-linux-targets";
            meta = {
              description = "Evaluate x86_64-linux host/image/security-summary derivation paths";
            };
          };
          scan-secrets = {
            type = "app";
            program = "${hostPkgs.writeShellApplication {
              name = "scan-secrets";
              text = ''
                export RG_BIN="${hostPkgs.ripgrep}/bin/rg"
                exec "${self}/scripts/scan_for_secrets.sh" "$@"
              '';
            }}/bin/scan-secrets";
            meta = {
              description = "Scan repository for common secret patterns and forbidden key files";
            };
          };
        };

      linuxOperatorApps = {
        smoke-quantum = {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "smoke-quantum";
            text = ''
              exec "${self}/tests/smoke_quantum.sh" "$@"
            '';
          }}/bin/smoke-quantum";
          meta = {
            description = "Run the quantum-lab smoke test";
          };
        };
        run-untrusted-notebook = {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "run-untrusted-notebook";
            text = ''
              exec "${self}/quantum/sandbox/run_untrusted_notebook.sh" "$@"
            '';
          }}/bin/run-untrusted-notebook";
          meta = {
            description = "Launch hardened rootless Podman notebook sandbox";
          };
        };
        build-linux-artifacts = {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "build-linux-artifacts";
            text = ''
              exec "${self}/scripts/build_linux_artifacts.sh" "$@"
            '';
          }}/bin/build-linux-artifacts";
          meta = {
            description = "Run checks and build Linux ISO/VMware/security artifacts";
          };
        };
        host-hardening-audit = {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "host-hardening-audit";
            text = ''
              exec "${self}/scripts/host_hardening_audit.sh" "$@"
            '';
          }}/bin/host-hardening-audit";
          meta = {
            description = "Run post-boot security baseline audit on a NixOS host";
          };
        };
      };
    in
    {
      nixosConfigurations = {
        quantumsec-desktop = desktop;
        quantumsec-headless = headless;
      };

      packages = hostDefaultPackages // {
        ${linuxSystem} = {
          quantumsec-desktop = desktop.config.system.build.toplevel;
          quantumsec-headless = headless.config.system.build.toplevel;
          quantumsec-security-summary-desktop = mkSecuritySummary "desktop" desktop;
          quantumsec-security-summary-headless = mkSecuritySummary "headless" headless;
          "quantumsec-iso" = mkImageOutput isoConfig "iso" "isoImage";
          "quantumsec-vmware" = mkImageOutput vmwareConfig "vmware" "vmwareImage";
          default = mkImageOutput isoConfig "iso" "isoImage";
        };
      };

      devShells.${linuxSystem} = quantumShells;

      apps =
        (lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ] mkEvalTargetsApp)
        // {
          ${linuxSystem} = (mkEvalTargetsApp linuxSystem) // linuxOperatorApps;
        };

      checks.${linuxSystem} = {
        "format-nix" = pkgs.runCommand "format-nix" { nativeBuildInputs = [ pkgs.alejandra ]; } ''
          cd ${self}
          alejandra --check .
          touch $out
        '';

        "shellcheck" = pkgs.runCommand "shellcheck"
          {
            nativeBuildInputs = [ pkgs.findutils pkgs.shellcheck ];
          }
          ''
            cd ${self}
            shell_files="$(find tests quantum/sandbox scripts -type f -name '*.sh' -print)"
            if [ -n "$shell_files" ]; then
              shellcheck $shell_files
            fi
            touch $out
          '';

        "python-examples-syntax" = pkgs.runCommand "python-examples-syntax"
          {
            nativeBuildInputs = [ pkgs.python311 ];
          }
          ''
            cd ${self}
            python - <<'PY'
            import ast
            import pathlib

            base = pathlib.Path("quantum/examples")
            for path in sorted(base.glob("*.py")):
                source = path.read_text(encoding="utf-8")
                ast.parse(source, filename=str(path))

            print("python-examples-syntax=ok")
            PY
            touch $out
          '';

        "no-secrets" = pkgs.runCommand "no-secrets"
          {
            nativeBuildInputs = [ pkgs.bash pkgs.git pkgs.ripgrep ];
          }
          ''
            cd ${self}
            export RG_BIN="${pkgs.ripgrep}/bin/rg"
            bash scripts/scan_for_secrets.sh
            touch $out
          '';

        "eval-shell-quantum-lab" = pkgs.writeText "eval-shell-quantum-lab.drvpath"
          quantumShells."quantum-lab".drvPath;
        "eval-shell-qiskit" = pkgs.writeText "eval-shell-qiskit.drvpath"
          quantumShells.qiskit.drvPath;
        "eval-shell-pennylane" = pkgs.writeText "eval-shell-pennylane.drvpath"
          quantumShells.pennylane.drvPath;
        "eval-shell-cirq" = pkgs.writeText "eval-shell-cirq.drvpath"
          quantumShells.cirq.drvPath;
        "eval-shell-pytket" = pkgs.writeText "eval-shell-pytket.drvpath"
          quantumShells.pytket.drvPath;

        "eval-nixos-headless" = pkgs.writeText "eval-nixos-headless.drvpath"
          headless.config.system.build.toplevel.drvPath;
        "eval-nixos-desktop" = pkgs.writeText "eval-nixos-desktop.drvpath"
          desktop.config.system.build.toplevel.drvPath;
        "eval-image-iso" = pkgs.writeText "eval-image-iso.drvpath"
          (mkImageOutput isoConfig "iso" "isoImage").drvPath;
        "eval-image-vmware" = pkgs.writeText "eval-image-vmware.drvpath"
          (mkImageOutput vmwareConfig "vmware" "vmwareImage").drvPath;
        "policy-desktop" = mkSecurityPolicyCheck "desktop" desktop;
        "policy-headless" = mkSecurityPolicyCheck "headless" headless;

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
