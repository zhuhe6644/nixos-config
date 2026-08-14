{ pkgs, username, ... }:

{
  imports = [ ./waybar.nix ];

  # --- NixOS ---

  programs.niri.enable = true;

  # Make Electron/Chromium apps run natively on Wayland.
  environment.variables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    xwayland-satellite # X11 clients under niri
    swaybg # wallpaper
    wl-clipboard
  ];

  # --- Home Manager ---

  home-manager.users.${username} = {
    xdg.configFile."niri/config.kdl".source = ./config.kdl;

    # Application launcher, bound to Mod+D in config.kdl.
    programs.fuzzel.enable = true;

    # Notification daemon.
    services.mako.enable = true;

    # Screen lock, bound to Super+Alt+L in config.kdl. The wrapper locks with
    # swaylock and powers the monitors off while the session stays locked.
    programs.swaylock.enable = true;
    home.packages = [ (pkgs.callPackage ./lock-and-blank.nix { }) ];
  };
}
