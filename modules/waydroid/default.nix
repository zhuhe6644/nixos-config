{ pkgs, ... }:

let
  # Autodetected gralloc=gbm / egl=mesa renders a black window on NVIDIA, so pin
  # the software renderer instead. https://wiki.nixos.org/wiki/Waydroid
  properties = {
    "ro.hardware.gralloc" = "default";
    "ro.hardware.egl" = "swiftshader";
  };

  propertiesJSON = pkgs.writeText "waydroid-properties.json" (builtins.toJSON properties);

  # Path inside the Android system image, and the same path under the overlay.
  keyLayout = "/system/usr/keylayout/Generic.kl";
in
{
  virtualisation.waydroid.enable = true;
  # Newer kernel versions may need the nftables-aware fork.
  virtualisation.waydroid.package = pkgs.waydroid-nftables;

  # Waydroid regenerates its properties in /var/lib/waydroid on init/upgrade, so
  # re-apply ours before the container starts.
  systemd.services.waydroid-properties = {
    description = "Apply declarative Waydroid properties";
    before = [ "waydroid-container.service" ];
    wantedBy = [
      "waydroid-container.service"
      "multi-user.target"
    ];
    # Nothing to patch until `waydroid init` has created the state directory.
    unitConfig.ConditionPathExists = "/var/lib/waydroid/waydroid.cfg";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.python3}/bin/python3 ${./properties.py} ${propertiesJSON}";
    };
  };

  # niri forwards a bare Super press to the focused window, and Android maps
  # keycodes 125/126 to META_* in Generic.kl, popping the assistant on every Mod
  # chord. Blanking them in the overlay's copy stops Android from seeing Super.
  systemd.services.waydroid-keylayout = {
    description = "Unmap Super in Waydroid's Android key layout";
    before = [ "waydroid-container.service" ];
    wantedBy = [
      "waydroid-container.service"
      "multi-user.target"
    ];
    # Nothing to derive from until `waydroid init` has fetched the images.
    unitConfig.ConditionPathExists = "/var/lib/waydroid/images/system.img";
    path = [
      pkgs.e2fsprogs
      pkgs.gnused
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      stock=$(mktemp)
      trap 'rm -f "$stock" "$stock.patched"' EXIT

      # debugfs reads the ext4 image in place, so the container can stay running.
      debugfs -R "dump ${keyLayout} $stock" /var/lib/waydroid/images/system.img
      if [ ! -s "$stock" ]; then
        echo "could not read ${keyLayout} out of system.img" >&2
        exit 1
      fi

      sed -e '/^key 12[56][[:space:]]/s|^|# niri owns Super, unmapped by NixOS config: |' \
        "$stock" >"$stock.patched"
      install -Dm0644 "$stock.patched" "/var/lib/waydroid/overlay${keyLayout}"
    '';
  };
}
