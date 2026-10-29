{ config, inputs, ... }:

let
  btrfsOptions = [
    "compress=zstd:1"
    "noatime"
  ];

  # The LVM partition disko creates on each drive.
  pv = disk: config.disko.devices.disk.${disk}.content.partitions.lvm.device;

  lvmDrive = device: {
    inherit device;
    content = {
      type = "gpt";
      partitions.lvm = {
        size = "100%";
        content = {
          type = "lvm_pv";
          vg = "pool";
        };
      };
    };
  };
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  # Drives are named by model and serial, so a renumbered /dev/nvmeN can never
  # point the installer at the wrong one.
  disko.devices = {
    disk = {
      # Crucial T705, PCIe 5.0: the boot partition, swap, and the start of the
      # root volume.
      t705 = {
        device = "/dev/disk/by-id/nvme-CT2000T705SSD3_2513E9B32575";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            lvm = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };

      # Samsung 980 PRO, PCIe 4.0 x4: the root volume continues here.
      samsung = lvmDrive "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0T330493A";

      # Micron 2450, PCIe 4.0 x2 behind the chipset: filled last.
      micron = lvmDrive "/dev/disk/by-id/nvme-Micron_2450_MTFDKBA1T0TFK_214632D25D6B";
    };

    lvm_vg.pool = {
      type = "lvm_vg";

      # Left to itself, LVM decides which drive each volume lands on. Create
      # both volumes here instead, so that swap and the start of root sit on
      # the T705, and root then continues on the 980 PRO and the Micron, in
      # that order. disko skips the volumes below because they already exist.
      preCreateHook = ''
        vgcreate pool ${pv "t705"} ${pv "samsung"} ${pv "micron"}
        lvcreate --yes --size 32G --name swap pool ${pv "t705"}
        lvcreate --yes --extents 100%PVS --name root pool ${pv "t705"}
        lvextend --yes --extents +100%PVS pool/root ${pv "samsung"}
        lvextend --yes --extents +100%PVS pool/root ${pv "micron"}
      '';

      lvs = {
        swap = {
          size = "32G";
          content = {
            type = "swap";
            # A new random key at every boot: nothing in swap outlives a
            # restart.
            randomEncryption = true;
            discardPolicy = "both";
          };
        };

        root = {
          size = "100%FREE";
          content = {
            type = "luks";
            name = "cryptroot";
            # Only exists while install-workstation runs. It holds a random key
            # for the first key slot, which the installer removes again once
            # the recovery key is in place.
            passwordFile = "/run/install-workstation/luks.key";
            # The drives report 512-byte blocks, so cryptsetup would encrypt in
            # 512-byte sectors. 4 KiB sectors need an eighth of the encryption
            # operations and match the 4 KiB blocks btrfs writes.
            extraFormatArgs = [ "--sector-size=4096" ];
            settings = {
              allowDiscards = true;
              bypassWorkqueues = true;
            };
            content = {
              type = "btrfs";
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = btrfsOptions;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOptions;
                };
              };
            };
          };
        };
      };
    };
  };

  # Deduplicates identical blocks across the whole file system in the
  # background, at idle priority. nix.optimise still hardlinks the store.
  services.beesd.filesystems.root = {
    spec = "/";
    hashTableSizeMB = 1024;
    verbosity = "crit";
  };

  # Swap gets a new random key at every boot, so a hibernation image could
  # never be read back. Don't offer hibernation at all.
  systemd.sleep.settings.Sleep = {
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };
}
