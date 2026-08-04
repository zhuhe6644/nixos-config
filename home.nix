{ config, pkgs, ... }:

let
  monitorOffDelay = 5;

  lockAndBlank = pkgs.writeShellApplication {
    name = "niri-lock-and-blank";

    runtimeInputs = with pkgs; [
      coreutils
      niri
      swayidle
      swaylock
      util-linux
    ];

    text = ''
      : "''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}"

      # Prevent multiple concurrent lock wrappers.
      exec 9>"$XDG_RUNTIME_DIR/niri-lock-and-blank.lock"
      flock -n 9 || exit 0

      idle_pid=""

      cleanup() {
        if [[ -n "$idle_pid" ]]; then
          kill "$idle_pid" 2>/dev/null || true
          wait "$idle_pid" 2>/dev/null || true
        fi

        # Ensure the displays are enabled after unlocking or on failure.
        niri msg action power-on-monitors >/dev/null 2>&1 || true
      }

      trap cleanup EXIT

      # This swayidle instance exists only while the screen is locked.
      swayidle -w \
        timeout ${toString monitorOffDelay} \
          'niri msg action power-off-monitors' \
        resume \
          'niri msg action power-on-monitors' &

      idle_pid=$!

      # Keep swaylock in the foreground. It exits after successful unlock.
      swaylock --show-failed-attempts
    '';
  };
in
{
  home.username = "lucoder";
  home.homeDirectory = "/home/lucoder";

  home.stateVersion = "26.05";

  home.packages = [
    lockAndBlank
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "He Zhu";
      user.email = "zhuhe6644@outlook.com";
    };
  };

  programs.alacritty.enable = true;

  programs.swaylock.enable = true;

  programs.fuzzel.enable = true;

  services.mako.enable = true;

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  xdg.dataFile = {
    "fcitx5/rime/default.custom.yaml" = {
      text = ''
        patch:
          __include: rime_ice_suggestion:/
      '';
    };
    "fcitx5/rime/rime_ice.custom.yaml" = {
      text = ''
        patch:
          "switches/@3/reset": 0
      '';
    };
  };
}
