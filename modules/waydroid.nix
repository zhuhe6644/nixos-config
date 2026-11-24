{ pkgs, ... }:

let
  # Autodetection picks the AMD render node on this NVIDIA desktop, resulting
  # in a black window. Use the software renderer for both fresh and existing images.
  renderer = pkgs.writeText "waydroid-renderer.prop" ''
    ro.hardware.gralloc=default
    ro.hardware.egl=swiftshader
  '';

  # Path inside the Android system image, and the same path under the overlay.
  keyLayout = "/system/usr/keylayout/Generic.kl";
in
{
  virtualisation.waydroid.enable = true;

  # init and upgrade can replace the image while the D-Bus service stays up.
  # Waydroid writes the base properties after it has finished installing images.
  systemd.paths.waydroid-setup = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "/var/lib/waydroid/waydroid_base.prop";
  };

  systemd.services.waydroid-setup = {
    description = "Apply the workstation renderer and key layout to Waydroid";
    before = [ "waydroid-container.service" ];
    wantedBy = [ "waydroid-container.service" ];
    path = [
      pkgs.crudini
      pkgs.diffutils
      pkgs.e2fsprogs
      pkgs.gnused
    ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "waydroid";
    };
    script = ''
      set -o pipefail
      cfg="$STATE_DIRECTORY/waydroid.cfg"
      base="$STATE_DIRECTORY/waydroid_base.prop"
      # Waydroid treats a rootfs directory plus a cfg as initialized. Leave an
      # interrupted install with a missing cfg eligible for `waydroid init`.
      if [ ! -f "$cfg" ] && [ -d "$STATE_DIRECTORY/rootfs" ]; then
        exit 0
      fi
      crudini --merge "$cfg" properties < ${renderer}
      if [ ! -f "$base" ]; then
        exit 0
      fi

      # Existing installations use their generated properties until the next
      # upgrade. Only write the watched file when a renderer value differs.
      while IFS='=' read -r key value; do
        if [[ $(crudini --get "$base" "" "$key" 2>/dev/null) != "$value" ]]; then
          crudini --ini-options=nospace --merge "$base" < ${renderer}
          break
        fi
      done < ${renderer}

      # Android maps Super to META_* and can open its assistant on desktop shortcuts.
      images=$(crudini --get "$cfg" waydroid images_path 2>/dev/null) || images="$STATE_DIRECTORY/images"
      target="$STATE_DIRECTORY/overlay${keyLayout}"
      mkdir -p "$(dirname "$target")"
      patched=$(mktemp "$target.XXXXXX")
      trap 'rm -f "$patched"' EXIT

      debugfs -R 'cat ${keyLayout}' "$images/system.img" |
        sed -E '/^[[:space:]]*key[[:space:]]+12[56][[:space:]]/s/^/# Super reserved for the desktop: /' >"$patched"
      if [ ! -s "$patched" ]; then
        echo "could not read ${keyLayout} out of system.img" >&2
        exit 1
      fi
      if ! cmp -s "$patched" "$target"; then
        chmod 0644 "$patched"
        mv -fT "$patched" "$target"
      fi
    '';
  };
}
