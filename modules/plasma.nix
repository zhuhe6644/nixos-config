{
  # A second desktop, for its HDR support when gaming.
  services.desktopManager.plasma6.enable = true;

  # pam_kwallet5 starts ksecretd at every login, ahead of gnome-keyring in the
  # PAM stack, and it would otherwise take org.freedesktop.secrets. Leave that
  # name to gnome-keyring; KDE apps reach kwallet by its own name regardless.
  environment.etc."xdg/kwalletrc".text = ''
    [org.freedesktop.secrets]
    apiEnabled=false
  '';
}
