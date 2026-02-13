{ lib, ... }:
{
  imports = [
    ../modules/security.nix
    ../modules/desktop.nix
    ../modules/quantum.nix
  ];

  networking.hostName = "quantumsec-desktop";

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.grub = {
    enable = lib.mkDefault true;
    device = lib.mkDefault "/dev/sda";
  };

  users.users.researcher = {
    isNormalUser = true;
    description = "QuantumSec Research Operator";
    extraGroups = [ "wheel" "networkmanager" "podman" "audio" "video" "input" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = lib.mkDefault [ ];
  };

  system.stateVersion = "24.11";
}
