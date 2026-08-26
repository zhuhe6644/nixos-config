{ pkgs, username, ... }:

let
  # Some apps do not use the Secret Service unless told to.
  useSecretService =
    package: package.override { commandLineArgs = "--password-store=gnome-libsecret"; };
in
{
  programs.firefox.enable = true;

  # gvfs backs nautilus' trash, network and mount support.
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    python3
    uv
    sops
    age
    (useSecretService google-chrome)
    vesktop
    telegram-desktop
    nautilus
  ];

  home-manager.users.${username} = {
    programs.alacritty.enable = true;
  };
}
