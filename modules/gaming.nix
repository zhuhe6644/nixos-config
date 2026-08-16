{ pkgs, username, ... }:

{
  programs.steam = {
    enable = true;
    # extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
    remotePlay.openFirewall = true;
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
    enableWsi = true;
  };
  programs.gamemode.enable = true;

  home-manager.users.${username} = {
    programs.mangohud.enable = true;
  };
}
