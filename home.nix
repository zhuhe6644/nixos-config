{ config, pkgs, ... }:

{
  home.username = "lucoder";
  home.homeDirectory = "/home/lucoder";

  home.stateVersion = "26.05";

  home.packages = [
    (pkgs.callPackage ./niri/lock-and-blank.nix { })
    pkgs.networkmanagerapplet
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "He Zhu";
      user.email = "zhuhe6644@outlook.com";
    };
  };

  programs.alacritty.enable = true;

  programs.swaylock.enable = true;

  programs.fuzzel.enable = true;

  services.mako.enable = true;

  services.network-manager-applet.enable = true;
  xsession.preferStatusNotifierItems = true;

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  xdg.dataFile = {
    "fcitx5/rime/default.custom.yaml" = {
      text = ''
        patch:
          __include: rime_ice_suggestion:/
      '';
    };
    "fcitx5/rime/rime_ice.custom.yaml" = {
      text = ''
        patch:
          "switches/@3/reset": 0
      '';
    };
  };

  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      modules-left = [ "niri/workspaces" ];
      modules-center = [ "niri/window" ];
      modules-right = [
        "tray"
        "clock"
      ];
      "niri/workspaces" = {
        format = "{id}";
        on-click = "activate";
      };
      "niri/window" = {
        format = "{title}";
      };
      tray = {
        spacing = 8;
        icon-size = 18;
      };
      clock = {
        format = "{:%H:%M}";
        tooltip-format = "{:%a, %b %d, %Y}";
      };
    };
    style = ''
      * { border: none; border-radius: 0; font-family: sans-serif; font-size: 13px; }
      window#waybar { background: rgba(20, 20, 20, 0.85); color: #e0e0e0; }
      #workspaces button.active { background: #3a3a3a; }
      #tray { padding: 0 8px; }
      #clock { padding: 0 10px; }
    '';
  };
}
