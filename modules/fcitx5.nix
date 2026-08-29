{ pkgs, username, ... }:

let
  # Drop the cache so the next fcitx5 start recompiles the patches below.
  clearRimeCache = ''
    rm -rf "$HOME/.local/share/fcitx5/rime/build"
  '';
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      addons = with pkgs; [
        fcitx5-gtk
        (fcitx5-rime.override { rimeDataPkgs = [ rime-ice ]; })
        fcitx5-fluent
      ];

      waylandFrontend = true;

      settings = {
        globalOptions = {
          # Hotkey = {
          # AltTriggerKeys = "";
          # EnumerateForwardKeys = "";
          # EnumerateBackwardKeys = "";
          # EnumerateGroupForwardKeys = "";
          # EnumerateGroupBackwardKeys = "";
          # ActivateKeys = "";
          # DeactivateKeys = "";
          # PrevPage = "";
          # NextPage = "";
          # PrevCandidate = "";
          # NextCandidate = "";
          # TogglePreedit = "";
          # };
          "Hotkey/TriggerKeys" = {
            "0" = "Control+space";
          };
        };

        addons = {
          classicui.globalSection = {
            Theme = "FluentDark-solid";
            Font = "Sans 12";
          };
        };

        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "rime";
        };
      };
    };
  };

  # Rime reads its overrides from the data directory, not the settings above.
  home-manager.users.${username} = {
    xdg.dataFile = {
      "fcitx5/rime/default.custom.yaml" = {
        text = ''
          patch:
            __include: rime_ice_suggestion:/
        '';
        onChange = clearRimeCache;
      };
      "fcitx5/rime/rime_ice.custom.yaml" = {
        text = ''
          patch:
            "switches/@3/reset": 0
            "menu/page_size": 9
        '';
        onChange = clearRimeCache;
      };
    };
  };
}
