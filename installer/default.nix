# The installer stick: a NixOS live system with install-workstation, and the
# workstation's whole system in its store, so installing needs no network.
#
#   nix build .#installer-iso
{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  username,
  ...
}:

let
  repo = inputs.self;
  workstation = repo.nixosConfigurations.workstation.config;
  luks = workstation.disko.devices.lvm_vg.pool.lvs.root.content;

  installWorkstation = pkgs.writeShellApplication {
    name = "install-workstation";
    runtimeInputs = [
      config.nix.package
      config.system.build.nixos-install
      pkgs.coreutils
      pkgs.cryptsetup
      pkgs.jq
      pkgs.lvm2
      pkgs.nixos-enter
      pkgs.nvme-cli
      pkgs.qrencode
      pkgs.sbctl
      pkgs.systemd
      pkgs.util-linux
    ];
    runtimeEnv = {
      DISKS = lib.concatStringsSep " " (
        lib.mapAttrsToList (name: disk: "${name}=${disk.device}") workstation.disko.devices.disk
      );
      DISKO_FORMAT = lib.getExe' workstation.system.build.format "disko-format";
      DISKO_MOUNT = lib.getExe' workstation.system.build.mount "disko-mount";
      LUKS_NAME = luks.name;
      LUKS_DEVICE = luks.device;
      LUKS_KEY = luks.passwordFile;
      PKI_BUNDLE = workstation.boot.lanzaboote.pkiBundle;
      REPO_REV = repo.shortRev or repo.dirtyShortRev or "unknown";
      # The workstation's system, which puts all of it on the stick.
      SYSTEM = "${workstation.system.build.toplevel}";
      TARGET_USER = username;
    };
    text = builtins.readFile ./install.sh;
  };
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  isoImage = {
    volumeID = "WORKSTATION-INSTALLER";
    # Fast enough to build with about 20 GB of store in it.
    squashfsCompression = "zstd -Xcompression-level 6";
  };
  image.baseName = lib.mkForce "workstation-installer";

  # ZFS isn't needed, and its module can lag behind new kernels.
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # nouveau would take the RTX 5080 over from the firmware's framebuffer,
  # which is all the installer needs to show text.
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Big enough to read on the 4K monitor.
  console = {
    earlySetup = true;
    font = "ter-v32n";
    packages = [ pkgs.terminus_font ];
  };

  environment.systemPackages = [
    installWorkstation
    # In case the firmware doesn't take the Secure Boot keys at the end.
    pkgs.sbctl
  ];

  services.getty.helpLine = lib.mkAfter ''

    To erase the drives and install the workstation: sudo install-workstation
  '';
}
