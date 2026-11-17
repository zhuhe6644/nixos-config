{
  pkgs,
  username,
  ...
}:

let
  bitwarden = pkgs.bitwarden-desktop.overrideAttrs (prev: {
    # The Linux autostart writer requires an absolute path. Point it at the
    # active system so a saved login item follows upgrades and rollbacks.
    postPatch = prev.postPatch + ''
      substituteInPlace apps/desktop/src/main/messaging.main.ts \
        --replace-fail 'execPath: app.getPath("exe"),' 'execPath: "/run/current-system/sw/bin/bitwarden",'
    '';
  });
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
    noctalia.u2f = {
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
  environment.systemPackages = [ bitwarden ];
  services.gnome.gcr-ssh-agent.enable = false;
  environment.sessionVariables.SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
}
