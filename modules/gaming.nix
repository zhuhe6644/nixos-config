{ pkgs, username, ... }:

{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
    remotePlay.openFirewall = true;
  };
  programs.gamescope = {
    enable = true;
    enableWsi = true;
  };

  # GE-Proton uses NTSync when /dev/ntsync exists.
  boot.kernelModules = [ "ntsync" ];

  # Keep the DualSense touchpad from moving the desktop pointer while leaving
  # it available to Steam and games over USB and Bluetooth.
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*DualSense*Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  home-manager.users.${username} = {
    programs.mangohud.enable = true;
  };
}
