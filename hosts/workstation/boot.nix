{ inputs, pkgs, ... }:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # Lanzaboote takes the place of the systemd-boot module and signs every boot
  # file with this machine's own Secure Boot keys. install-workstation creates
  # the keys and enrolls them in the firmware, next to Microsoft's, which the
  # graphics card's firmware needs.
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 100;
    settings = {
      # No menu unless a key is held at start-up, and no editing of the kernel
      # command line from it.
      timeout = 0;
      editor = false;
    };
  };

  # With emergency access off, a failed start-up can't drop to a root shell in
  # the initrd.
  boot.initrd.systemd.emergencyAccess = false;

  # Firmware updates, including Secure Boot's list of revoked signatures (dbx).
  services.fwupd.enable = true;

  # To inspect and manage the Secure Boot keys.
  environment.systemPackages = [ pkgs.sbctl ];
}
