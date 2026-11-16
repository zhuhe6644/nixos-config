{ pkgs, ... }:

{
  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  # VPN traffic arrives on a different interface than the routing table expects.
  networking.firewall.checkReversePath = "loose";

  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Allow up to 128 MiB receive and 256 MiB send.
    "net.ipv4.tcp_rmem" = "4096 131072 134217728";
    "net.ipv4.tcp_wmem" = "4096 16384 268435456";
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = [
    pkgs.wireguard-tools
    # Keep the VPN profile editor available. Noctalia provides the network applet.
    (pkgs.linkFarm "nm-connection-editor" {
      "bin/nm-connection-editor" = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
      "share/applications/nm-connection-editor.desktop" =
        "${pkgs.networkmanagerapplet}/share/applications/nm-connection-editor.desktop";
    })
  ];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = "opportunistic";
      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };
}
