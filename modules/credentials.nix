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
}
