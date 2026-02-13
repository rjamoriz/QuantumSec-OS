{ pkgs, ... }:
{
  networking.networkmanager.enable = true;

  security.polkit.enable = true;
  services.dbus.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.sway.enable = true;
  programs.dconf.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --sessions /run/current-system/sw/share/wayland-sessions --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  environment.systemPackages = with pkgs; [
    foot
    grim
    mako
    slurp
    swaybg
    waybar
    wl-clipboard
    wofi
  ];
}
