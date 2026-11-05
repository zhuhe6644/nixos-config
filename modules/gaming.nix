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

  # The DualSense's touchpad registers as an ordinary touchpad, so niri and
  # Plasma move the pointer with it. Hide it from libinput only, so Steam and
  # games still read it. The glob covers its USB and Bluetooth names.
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*DualSense*Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  home-manager.users.${username} = {
    programs.mangohud.enable = true;
  };
}
