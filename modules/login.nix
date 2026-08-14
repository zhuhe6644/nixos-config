{ pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet";
      };
    };
    useTextGreeter = true;
  };

  # Unlock the login keyring with the password entered at the greeter above.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Provides the prompter the keyring uses to ask for secrets.
  environment.systemPackages = [ pkgs.gcr ];
}
