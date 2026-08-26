{
  imports = [
    ./hardware-configuration.nix

    ../../modules/apps.nix
    ../../modules/audio.nix
    ../../modules/claude-desktop.nix
    ../../modules/credentials.nix
    ../../modules/fcitx5.nix
    ../../modules/gaming.nix
    ../../modules/git.nix
    ../../modules/login.nix
    ../../modules/networking.nix
    ../../modules/niri
    ../../modules/plasma.nix
    ../../modules/system.nix
    ../../modules/users.nix
    ../../modules/vscode.nix
    ../../modules/waydroid
  ];

  networking.hostName = "workstation";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 100;
  boot.loader.efi.canTouchEfiVariables = true;

  # Discrete NVIDIA GPU.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  # The NixOS release this machine was first installed with. Never change it.
  system.stateVersion = "26.05";
}
