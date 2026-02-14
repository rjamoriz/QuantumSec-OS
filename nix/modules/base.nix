{ pkgs, ... }:
{
  networking.hostName = "quantumsec";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.quantum = {
    isNormalUser = true;
    description = "QuantumSec Operator";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "quantum";
    openssh.authorizedKeys.keys = [ ];
  };

  environment.systemPackages = with pkgs; [
    git
    jq
    tmux
    vim
    wget
    curl
  ];

  # Keep first install practical for VMware demos; switch to immutable users in hardening v2.
  users.mutableUsers = true;

  system.stateVersion = "24.11";
}
