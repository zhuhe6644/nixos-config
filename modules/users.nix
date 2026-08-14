{ inputs, username, ... }:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  # --- NixOS ---

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # --- Home Manager ---

  # Run Home Manager as a NixOS module, so every feature module can define its
  # user-level configuration alongside its system-level configuration via
  # `home-manager.users.${username}`.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs username; };

    users.${username} = {
      home.username = username;
      home.homeDirectory = "/home/${username}";

      home.stateVersion = "26.05";

      programs.home-manager.enable = true;
    };
  };
}
