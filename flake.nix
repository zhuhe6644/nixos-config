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

          packages.niri-lock-and-blank = pkgs.callPackage ./modules/niri/lock-and-blank.nix { };
        };

      # The system is set by `nixpkgs.hostPlatform` in the host's
      # hardware-configuration.nix, so `nixosSystem` needs no `system` argument.
      flake.nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          username = "lucoder";
        };

        modules = [ ./hosts/nixos ];
      };
    };
}
