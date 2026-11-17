{
  pkgs,
  username,
  ...
}:

{
  programs.firefox.enable = true;

  # gvfs backs nautilus' trash, network and mount support.
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    sops
    age
    google-chrome
    vesktop
    telegram-desktop
    nautilus
  ];

  home-manager.users.${username} = {
    programs.kitty.enable = true;

    xdg.configFile."umbriel-mimeapps.list".text = ''
      [Default Applications]
      inode/directory=org.gnome.Nautilus.desktop;
    '';
  };
}
