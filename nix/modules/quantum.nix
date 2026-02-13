{ pkgs, ... }:
{
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

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
    bash
    git
    gnupg
    podman-compose
  ];
}
