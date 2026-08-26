{
  lib,
  pkgs,
  username,
  ...
}:

let
  # nixd evaluates this flake to know which options exist, so it needs an
  # absolute path. Hardcoding it also keeps completion working when VS Code is
  # opened somewhere other than this repo.
  configPath = "/home/${username}/Projects/nixos-config";
in
{
  home-manager.users.${username} = {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode.override {
        # Pinned to the Secret Service for the reason described in apps.nix.
        commandLineArgs = "--password-store=gnome-libsecret";
      };

      profiles.default = {
        extensions = [ pkgs.vscode-extensions.jnoortheen.nix-ide ];

        userSettings = {
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = lib.getExe pkgs.nixd;
          "nix.serverSettings".nixd = {
            nixpkgs.expr = ''import (builtins.getFlake "${configPath}").inputs.nixpkgs { }'';
            # nix.formatterPath is ignored while the language server is on.
            formatting.command = [
              (lib.getExe pkgs.nixfmt)
              "-"
            ];
            options = {
              nixos.expr = ''(builtins.getFlake "${configPath}").nixosConfigurations.workstation.options'';
              home-manager.expr = ''(builtins.getFlake "${configPath}").nixosConfigurations.workstation.options.home-manager.users.type.getSubOptions [ ]'';
            };
          };

          "editor.formatOnSave" = true;
          "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
      };
    };
  };
}
