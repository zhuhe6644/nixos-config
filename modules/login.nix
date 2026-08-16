{ pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet";
      };
    };
    useTextGreeter = true;
  };

  # Secret Service backend for apps that store credentials.
  services.gnome.gnome-keyring.enable = true;
}
