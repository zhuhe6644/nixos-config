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
  # Keep the credential mapping root-owned: these PAM services can authorize
  # privileged actions.
  environment.etc."u2f-mappings".text = ''
    ${username}:svqTW0847OmVKGUGG6+LvY4Jtt3eCJBLN8/nFBMv9hrav3CMws6M9L1iVoU8zinoQqrn36ph6G3DSOQGx4AuzqdJqc0CCh2ySH6QZgKvUXJtwdVnlYY+N2SDJMKAJu2M,Aom66KKnFbYcmVP7oL6L+DF8X3eDEcsqSUpmLMVzmU447fwqLp5h9V6OBnrk6cZXlGdyKzXZOKrMmGwV5y0rlw==,es256,+presence+verification
  '';

  security.pam.u2f.settings = {
    authfile = "/etc/u2f-mappings";
    cue = true;

    # Require the Bio3's fingerprint sensor for user verification.
    userverification = 1;
    pinverification = 0;

    # To use the key PIN instead of its fingerprint in the future:
    # userverification = 0;
    # pinverification = 1;
  };

  security.pam.services = {
    "polkit-1".u2f = {
      enable = true;
      control = "sufficient";
    };
    sudo.u2f = {
      enable = true;
      control = "sufficient";
    };
    swaylock.u2f = {
      enable = true;
      control = "sufficient";
    };
    kde.u2f = {
      enable = true;
      control = "sufficient";
    };
  };

  # Allow polkit to access FIDO2 devices when U2F is enabled per service.
  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;
    DeviceAllow = [
      "/dev/urandom r"
      "char-hidraw rw"
    ];
  };

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
