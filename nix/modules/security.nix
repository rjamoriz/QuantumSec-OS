{...}: {
  networking.firewall.enable = true;
  networking.firewall.allowPing = false;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["quantum"];
      X11Forwarding = false;
      AllowTcpForwarding = "no";
      AllowAgentForwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };

  services.printing.enable = false;
  services.avahi.enable = false;

  nix.settings = {
    sandbox = true;
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "@wheel"];
    allowed-users = ["@wheel"];
    auto-optimise-store = true;
    substituters = ["https://cache.nixos.org/"];
    trusted-substituters = ["https://cache.nixos.org/"];
  };

  security.sudo.wheelNeedsPassword = true;
  security.apparmor.enable = true;

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.sysrq" = 0;
    "net.core.bpf_jit_harden" = 2;
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
}
