{ pkgs, ... }:

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
}
