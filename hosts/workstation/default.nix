{ config, ... }:

{
  imports = [
    ./boot.nix
    ./disks.nix
    ./hardware-configuration.nix
    ./tpm.nix

    ../../modules/agents.nix
    ../../modules/apps.nix
    ../../modules/audio.nix
    ../../modules/bluetooth.nix
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
  # Fan control app.
  programs.coolercontrol.enable = true;

  # The NixOS release this machine was first installed with. Never change it.
  system.stateVersion = "26.11";
}
