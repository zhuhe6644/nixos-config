{ inputs, username, ... }:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # Home Manager as a NixOS module, so each feature module can define its
  # user-level config next to its system-level config.
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
