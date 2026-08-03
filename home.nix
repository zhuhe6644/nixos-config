{ config, pkgs, ... }:

{
  home.username = "lucoder";
  home.homeDirectory = "/home/lucoder";

  home.stateVersion = "26.05";

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

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
}
