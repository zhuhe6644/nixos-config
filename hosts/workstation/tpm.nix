{
  config,
  lib,
  pkgs,
  ...
}:

let
  luksDevice = config.boot.initrd.luks.devices.cryptroot.device;
in
{
  # Start-up unlocks the disk with the TPM, which gives the key out only while
  #  - the Secure Boot state is the one the key was sealed to (PCR 7), and
  #  - PCR 15 is still zero. It is from power-on until tpm-lock below runs,
  #    right after start-up has opened the disk, and it can't go back to zero
  #    until the next start.
  # So nothing that runs once the disk is open can get the key from the TPM.
  # That includes the system on a disk swapped in for this one, with a key of
  # its own: start-up would open that disk, but the TPM is locked before
  # anything on it runs.
  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];

  # systemd-pcrextend skips measuring unless this says to, or an EFI variable
  # says the boot stub measured too. Lanzaboote's stub sets that variable, but
  # other systems can write EFI variables as well, while the kernel command line
  # is part of the signed boot image.
  boot.kernelParams = [ "systemd.tpm2_measured_os=yes" ];

  boot.initrd.systemd.services.tpm-lock = {
    description = "Lock the disk key in the TPM until the next start";
    # Ordered after tpm2.target, which systemd pulls in when the firmware reports
    # a TPM, to wait for it. Pulled in here as well, it would make start-up wait
    # 90 seconds for a TPM that's turned off.
    after = [
      "systemd-cryptsetup@cryptroot.service"
      "tpm2.target"
    ];
    # The root file system isn't mounted unless this succeeds. If the TPM is
    # there but failing, start-up stops here; turning the TPM off in the BIOS
    # gets past it, with the recovery key.
    before = [ "sysroot.mount" ];
    requiredBy = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      # Otherwise it's inactive again once done, and every later start job for
      # sysroot.mount runs it once more.
      RemainAfterExit = true;
    };
    script = ''
      pcr=/sys/class/tpm/tpm0/pcr-sha256/15
      # Without a TPM, there's no key in it to lock.
      if [ ! -e "$pcr" ]; then
        echo "There's no TPM."
        exit 0
      fi
      ${config.boot.initrd.systemd.package}/lib/systemd/systemd-pcrextend --pcr=15 disk-opened
      read -r value <"$pcr"
      if [[ $value =~ ^0+$ ]]; then
        echo "PCR 15 is still zero, so the TPM would still give out the disk key." >&2
        exit 1
      fi
    '';
  };

  # Start-up asks for the recovery key whenever the TPM won't unlock the disk:
  # on the first start after installing, and after anything that changes the
  # Secure Boot state, such as a BIOS update. Each time, this seals the key to
  # the TPM again, so the next start unlocks on its own. It needs no key of its
  # own: it uses the recovery key just typed.
  systemd.services.tpm-enroll = {
    description = "Seal the disk key to the TPM";
    wantedBy = [ "multi-user.target" ];
    after = [
      "tpm2.target"
      "systemd-tpm2-setup.service"
    ];
    path = [ pkgs.keyutils ];
    serviceConfig = {
      Type = "oneshot";
      # Links in root's keyring, where systemd-cryptsetup keeps whatever was
      # typed at the start-up prompt, for 2.5 minutes.
      KeyringMode = "shared";
    };
    script = ''
      # Nothing was typed if the TPM unlocked the disk.
      if ! key=$(keyctl request user cryptsetup 2>/dev/null); then
        echo "The TPM unlocked the disk."
        exit 0
      fi
      # Checked before anything is wiped: the TPM may only be turned off for now.
      if [ ! -e /sys/class/tpm/tpm0 ]; then
        echo "There's no TPM, as when it's turned off in the BIOS, so the disk key isn't sealed to it." >&2
        exit 1
      fi

      efi_byte() {
        od -An -t u1 -j 4 -N 1 "/sys/firmware/efi/efivars/$1-8be4df61-93ca-11d2-aa0d-00e098032b8c" | tr -d ' '
      }
      # Sealed without Secure Boot enforced, the key would open for any system
      # at all, signed or not.
      if [ "$(efi_byte SetupMode)" != 0 ]; then
        echo "The firmware has no Secure Boot keys, as after some BIOS updates, so the disk key isn't sealed to the TPM. Enroll them again with 'sudo sbctl enroll-keys --microsoft' and restart." >&2
        exit 1
      fi
      if [ "$(efi_byte SecureBoot)" != 1 ]; then
        echo "Secure Boot is off, so the disk key isn't sealed to the TPM. Turn it on in the BIOS." >&2
        exit 1
      fi

      # Everything typed, each followed by a NUL byte. The last one opened the
      # disk.
      mapfile -d "" typed < <(keyctl pipe "$key")

      # Wiped first: with PCR 7 unchanged (say, after the TPM was cleared),
      # systemd-cryptenroll would keep the old, useless enrollment instead.
      systemd-cryptenroll --wipe-slot=tpm2 ${luksDevice}
      # tpm-lock has changed PCR 15 by now, so the zero to seal to is spelled
      # out rather than read from the TPM.
      printf %s "''${typed[-1]}" |
        systemd-cryptenroll --unlock-key-file=/dev/stdin --tpm2-device=auto \
          --tpm2-pcrs=7+15:sha256=${lib.strings.replicate 64 "0"} ${luksDevice}
      echo "Sealed the disk key to the TPM: the next start unlocks on its own."
    '';
  };
}
