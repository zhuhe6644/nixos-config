{
  inputs,
  pkgs,
  username,
  ...
}:

{
  imports = [ inputs.claude-desktop.nixosModules.default ];

  programs.claude-desktop.enable = true;
  programs.claude-desktop.cowork.kvmUsers = [ username ];

  # Pinned to the Secret Service for the reason described in apps.nix.
  programs.claude-desktop.package =
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default.override
      {
        commandLineArgs = "--password-store=gnome-libsecret";
      };
}
