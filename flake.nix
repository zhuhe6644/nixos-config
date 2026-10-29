{
  description = "lucoder's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.2.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    let
      username = "lucoder";
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;

          # The installer stick, see installer/default.nix.
          packages.installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
        };

      # `nixpkgs.hostPlatform` in hardware-configuration.nix sets the system.
      flake.nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username; };

        modules = [ ./hosts/workstation ];
      };

      flake.nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username; };

        modules = [ ./installer ];
      };
    };
}
