{ pkgs, username, ... }:

{
  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  # VPN traffic arrives on a different interface than the routing table expects.
  networking.firewall.checkReversePath = "loose";

  environment.systemPackages = [ pkgs.wireguard-tools ];

  home-manager.users.${username} = {
    services.network-manager-applet.enable = true;

    # Ask nm-applet for a StatusNotifierItem instead of a legacy XEmbed icon,
    # which is what the waybar tray understands.
    xsession.preferStatusNotifierItems = true;

    # The applet module puts nothing on PATH; installing the package is what
    # makes `nm-connection-editor` launchable from a shell or from fuzzel.
    home.packages = [ pkgs.networkmanagerapplet ];
  };
}
