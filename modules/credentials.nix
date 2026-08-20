{
  config,
  pkgs,
  username,
  ...
}:

let
  homeDir = config.users.users.${username}.home;
in
{
  # Secret Service backend for apps that store credentials.
  services.gnome.gnome-keyring.enable = true;

  # Bitwarden's SSH agent, in place of gnome-keyring's.
  environment.systemPackages = [ pkgs.bitwarden-desktop ];
  services.gnome.gcr-ssh-agent.enable = false;
  environment.sessionVariables.SSH_AUTH_SOCK = "${homeDir}/.bitwarden-ssh-agent.sock";

  # The browser extension does not do biometrics itself; it asks the desktop app
  # to unlock, over native messaging. The app installs the manifest for that on
  # its own, but only into browser directories that already exist, and Firefox
  # stopped creating this one when its profile moved under ~/.config. Leaving
  # the directory here is enough for the app to fill it in on every start.
  systemd.user.tmpfiles.users.${username}.rules = [ "d %h/.mozilla 0755 - - -" ];
}
