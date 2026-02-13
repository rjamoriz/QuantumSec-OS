{ lib, ... }:
{
  imports = [
    ../modules/security.nix
    ../modules/headless.nix
    ../modules/quantum.nix
  ];

  networking.hostName = "quantumsec-headless";

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.researcher = {
    isNormalUser = true;
    description = "QuantumSec Research Operator";
    extraGroups = [ "wheel" "networkmanager" "podman" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = lib.mkDefault [ ];
  };

  system.stateVersion = "24.11";
}
