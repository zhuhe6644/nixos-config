{
  imports = [
    ./hardware-configuration.nix

    ../../modules/apps.nix
    ../../modules/audio.nix
    ../../modules/claude-desktop.nix
    ../../modules/fcitx5.nix
    ../../modules/login.nix
    ../../modules/networking.nix
    ../../modules/niri
    ../../modules/system.nix
    ../../modules/users.nix
    ../../modules/waydroid
  ];

  networking.hostName = "nixos";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Discrete NVIDIA GPU.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  # This option defines the first version of NixOS you have installed on this
  # particular machine, and is used to maintain compatibility with application
  # data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any
  # reason, even if you've upgraded your system to a new NixOS release.
  system.stateVersion = "26.05";
}
