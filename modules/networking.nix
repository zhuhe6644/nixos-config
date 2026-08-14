{ pkgs, username, ... }:

{
  # --- NixOS ---

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  # VPN traffic arrives on a different interface than the routing table expects.
  networking.firewall.checkReversePath = "loose";

  environment.systemPackages = [ pkgs.wireguard-tools ];

  # --- Home Manager ---

  home-manager.users.${username} = {
    services.network-manager-applet.enable = true;

    # Ask nm-applet for a StatusNotifierItem instead of a legacy XEmbed icon,
    # which is what the waybar tray understands.
    xsession.preferStatusNotifierItems = true;

    # The applet module only wires up a systemd user service pointing at an
    # absolute store path; it puts nothing on PATH. Installing the package as
    # well is what makes `nm-connection-editor` launchable, both from a shell
    # and from the fuzzel entry, whose Exec is a bare command name.
    home.packages = [ pkgs.networkmanagerapplet ];
  };
}
