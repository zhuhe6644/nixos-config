{ pkgs, ... }:

{
  # The newest Nix release, ahead of nixpkgs' default.
  nix.package = pkgs.nixVersions.latest;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  boot.tmp.useTmpfs = true;

  # The newest kernel, not the LTS default.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.zswap = {
    enable = true;
    compressor = "zstd";
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Run unpatched dynamically linked binaries (e.g. downloaded toolchains).
  programs.nix-ld.enable = true;

  # Build and run aarch64 binaries under QEMU emulation.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
