{ pkgs, ... }:

{
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    #   pulse.enable = true;
  };

  # Graphical mixer / device routing.
  environment.systemPackages = [ pkgs.pwvucontrol ];
}
