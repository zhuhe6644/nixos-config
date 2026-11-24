{ config, ... }:

{
  imports = [
    ./boot.nix
    ./coolercontrol
    ./disks.nix
    ./hardware-configuration.nix
    ./tpm.nix

    ../../modules/agents.nix
    ../../modules/apps.nix
    ../../modules/audio.nix
    ../../modules/credentials.nix
    ../../modules/fcitx5.nix
    ../../modules/gaming.nix
    ../../modules/git.nix
    ../../modules/networking.nix
    ../../modules/noctalia.nix
    ../../modules/system.nix
    ../../modules/users.nix
    ../../modules/vscode.nix
    ../../modules/waydroid.nix
  ];

  networking.hostName = "workstation";

  # Discrete NVIDIA GPU.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  # The newer of NVIDIA's production and new feature drivers.
  hardware.nvidia.branch = "latest";

  # GPU Configuration.
  services.lact.enable = true;

  # Motherboard fan controller driver.
  boot.extraModulePackages = [ config.boot.kernelPackages.nct6687d ];
  boot.kernelModules = [ "nct6687" ];
  # Writes all seven points of a system fan's curve rather than only the first point.
  boot.extraModprobeConfig = ''
    options nct6687 msi_fan_brute_force=1
  '';

  # The NixOS release this machine was first installed with. Never change it.
  system.stateVersion = "26.11";
}
