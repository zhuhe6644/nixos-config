{ pkgs, ... }:

{
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    #   pulse.enable = true;
  };

  # Gives PipeWire's audio threads realtime priority.
  security.rtkit.enable = true;

  # Graphical mixer / device routing.
  environment.systemPackages = [ pkgs.pwvucontrol ];
}
