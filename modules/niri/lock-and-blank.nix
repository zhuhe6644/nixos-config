{
  writeShellApplication,
  coreutils,
  niri,
  swayidle,
  swaylock,
  util-linux,

  # Seconds before the monitors power off after locking.
  monitorOffDelay ? 10,
}:

writeShellApplication {
  name = "niri-lock-and-blank";

  runtimeInputs = [
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
}
