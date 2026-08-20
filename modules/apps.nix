{ pkgs, username, ... }:

let
  # Some apps do not use the Secret Service unless told to.
  useSecretService =
    package: package.override { commandLineArgs = "--password-store=gnome-libsecret"; };
in
{
  programs.firefox.enable = true;

  programs.vscode.enable = true;
  programs.vscode.package = useSecretService pkgs.vscode;

  # gvfs backs nautilus' trash, network and mount support.
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    (useSecretService google-chrome)
    python3
    uv
    vesktop
    telegram-desktop
    nautilus
  ];

  home-manager.users.${username} = {
    programs.alacritty.enable = true;
  };
}
