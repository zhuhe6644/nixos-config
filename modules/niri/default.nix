{
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [ ./waybar.nix ];

  programs.niri.enable = true;

  # Make Electron/Chromium apps run natively on Wayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    xwayland-satellite # X11 clients under niri
    wl-clipboard
  ];

  home-manager.users.${username} = {
    xdg.configFile."niri/config.kdl".source = ./config.kdl;

    # Application launcher, bound to Mod+D in config.kdl.
    programs.fuzzel.enable = true;

    # Notification daemon.
    services.mako.enable = true;

    # Screen lock, bound to Super+Alt+L in config.kdl. Blanks the monitors while locked.
    programs.swaylock.enable = true;
    home.packages = [ (pkgs.callPackage ./lock-and-blank.nix { }) ];

    # Overwrite this shared dconf key again on every niri start.
    systemd.user.services.dark-color-scheme = {
      Unit = {
        Description = "Prefer a dark colour scheme";
        After = [ "niri.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkgs.dconf} write /org/gnome/desktop/interface/color-scheme \"'prefer-dark'\"";
      };
      Install.WantedBy = [ "niri.service" ];
    };

    # Wallpaper. Bound to niri.service.
    systemd.user.services.swaybg = {
      Unit = {
        Description = "Wallpaper";
        PartOf = [ "niri.service" ];
        After = [ "niri.service" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.swaybg} --mode fill --image ${./earth.jpg}";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "niri.service" ];
    };
  };
}
