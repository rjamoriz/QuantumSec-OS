{ pkgs, ... }:
{
  networking.networkmanager.enable = true;

  services.printing.enable = false;
  services.avahi.enable = false;

  environment.systemPackages = with pkgs; [
    htop
    jq
    tmux
    vim
  ];
}
