{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;
  };

  # Gives PipeWire's audio threads realtime priority.
  security.rtkit.enable = true;
  # Graphical mixer / device routing.
  environment.systemPackages = [ pkgs.pwvucontrol ];
}
