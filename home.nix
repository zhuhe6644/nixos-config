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

  dconf.settings = {
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
    };
  };
}
