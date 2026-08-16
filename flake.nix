{
  description = "lucoder's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    claude-desktop.url = "github:nmcbride/claude-desktop-nix";
    claude-desktop.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
        };

      # `nixpkgs.hostPlatform` in hardware-configuration.nix sets the system.
      flake.nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          username = "lucoder";
        };

        modules = [ ./hosts/workstation ];
      };
    };
}
