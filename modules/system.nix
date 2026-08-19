{ pkgs, ... }:

{
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

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Run unpatched dynamically linked binaries (e.g. downloaded toolchains).
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # steam-run.fhsenv.args.multiPkgs pkgs
      # (pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
      stdenv.cc.cc.lib # libstdc++, libgcc_s
      zlib
      openssl
    ];
  };

  # Build and run aarch64 binaries under QEMU emulation.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
