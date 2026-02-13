{ pkgs, ... }:
{
  networking.networkmanager.enable = true;

  services.printing.enable = false;
  services.avahi.enable = false;

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" "--filter=until=72h" ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
    htop
    jq
    podman-compose
    tmux
    vim
  ];
}
