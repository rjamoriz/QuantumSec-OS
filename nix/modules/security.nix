{ lib, pkgs, ... }:
{
  networking.firewall.enable = lib.mkDefault true;
  networking.firewall.allowPing = false;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AllowTcpForwarding = "no";
      AllowAgentForwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };

  nix.settings = {
    sandbox = true;
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    allowed-users = [ "@wheel" ];
    auto-optimise-store = true;
    substituters = [ "https://cache.nixos.org/" ];
    trusted-substituters = [ "https://cache.nixos.org/" ];
  };

  security.sudo.wheelNeedsPassword = true;
  users.mutableUsers = lib.mkDefault true;

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "kernel.sysrq" = 0;
    "fs.protected_fifos" = 2;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };

  systemd.services.quantumsec-baseline-report = {
    description = "Record hardened baseline values";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.bash}/bin/bash -eu -c '
          umask 077
          out="/var/lib/quantumsec/security-baseline.txt"
          mkdir -p /var/lib/quantumsec
          {
            echo "Generated: $(date -Is)"
            echo "kernel.kptr_restrict=$(cat /proc/sys/kernel/kptr_restrict)"
            echo "kernel.dmesg_restrict=$(cat /proc/sys/kernel/dmesg_restrict)"
            echo "kernel.unprivileged_bpf_disabled=$(cat /proc/sys/kernel/unprivileged_bpf_disabled)"
            echo "net.ipv4.tcp_syncookies=$(cat /proc/sys/net/ipv4/tcp_syncookies)"
          } > "$out"
        '
      '';
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      LockPersonality = true;
      RestrictSUIDSGID = true;
      StateDirectory = "quantumsec";
      ReadWritePaths = [ "/var/lib/quantumsec" ];
    };
  };

  systemd.timers.quantumsec-baseline-report = {
    description = "Periodic hardened baseline report refresh";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "24h";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
