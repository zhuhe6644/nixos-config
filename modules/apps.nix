{ pkgs, username, ... }:

{
  # --- NixOS ---

  programs.firefox.enable = true;

  programs.vscode.enable = true;

  # Android apps.
  virtualisation.waydroid.enable = true;
  # Newer kernel versions may need
  virtualisation.waydroid.package = pkgs.waydroid-nftables;

  # gvfs backs nautilus' trash, network and mount support.
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    google-chrome
    git
    discord
    telegram-desktop
    nautilus
  ];

  # --- Home Manager ---

  home-manager.users.${username} = {
    programs.alacritty.enable = true;

    programs.git = {
      enable = true;
      settings = {
        user.name = "He Zhu";
        user.email = "zhuhe6644@outlook.com";
      };
    };
  };
}
