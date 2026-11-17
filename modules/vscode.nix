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
  workstation = ''(builtins.getFlake "/home/${username}/Projects/nixos-config").nixosConfigurations.workstation'';
in
{
  home-manager.users.${username} = {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode.override {
        # Electron's synchronous safeStorage defaults to basic_text on Umbriel.
        commandLineArgs = "--password-store=gnome-libsecret";
      };

      profiles.default = {
        extensions = [ pkgs.vscode-extensions.jnoortheen.nix-ide ];

        userSettings = {
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = lib.getExe pkgs.nixd;
          "nix.serverSettings".nixd = {
            nixpkgs.expr = "${workstation}.pkgs";
            # nix.formatterPath is ignored while the language server is on.
            formatting.command = [
              (lib.getExe pkgs.nixfmt)
              "-"
            ];
            options = {
              nixos.expr = "${workstation}.options";
              home-manager.expr = "${workstation}.options.home-manager.users.type.getSubOptions [ ]";
            };
          };

          "editor.formatOnSave" = true;
          "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
      };
    };
  };
}
