{ username, ... }:

{
  hardware.bluetooth.enable = true;

  # Tray applet and pairing UI for niri. Plasma adds its own once Bluetooth is
  # enabled.
  services.blueman.enable = true;

  home-manager.users.${username} = {
    services.blueman-applet = {
      enable = true;
      systemdTargets = [ "niri.service" ];
    };

    # The blueman package also ships an XDG autostart entry, which both niri and
    # Plasma run. Hide it so the applet only starts through the service above.
    xdg.configFile."autostart/blueman.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
  };
}
