{ pkgs, ... }:

{
  imports = [ ./fcitx5.nix ];

  environment.variables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    swaybg
    nautilus
    pwvucontrol
  ];

  programs.niri.enable = true;

  services.gvfs.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet";
      };
    };
    useTextGreeter = true;
  };
}
