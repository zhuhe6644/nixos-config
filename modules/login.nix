{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Every enabled desktop's .desktop files, merged into one directory by the
  # display-manager module.
  sessions = config.services.displayManager.sessionData.desktops;
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = lib.concatStringsSep " " [
          "${pkgs.tuigreet}/bin/tuigreet"
          "--sessions ${sessions}/share/wayland-sessions"
          "--xsessions ${sessions}/share/xsessions"
          "--time"
        ];
      };
    };
    useTextGreeter = true;
  };

  services.displayManager.defaultSession = "niri";

  # Secret Service backend for apps that store credentials.
  services.gnome.gnome-keyring.enable = true;
}
