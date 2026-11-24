{ ... }:

{
  # Fan control app.
  programs.coolercontrol.enable = true;

  # CoolerControl rewrites its own config on every mode change and when it stops, so
  # the files can't be links into the store. Copy them in before each start instead.
  systemd.services.coolercontrold.preStart = ''
    install -Dm644 ${./config.toml} /etc/coolercontrol/config.toml
    install -Dm644 ${./modes.json} /etc/coolercontrol/modes.json
    install -Dm644 ${./calibrations.json} /etc/coolercontrol/calibrations.json
  '';
}
