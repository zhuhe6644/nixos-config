{ username, ... }:

{
  # Started by `spawn-at-startup "waybar"` in config.kdl.
  home-manager.users.${username} = {
    programs.waybar = {
      enable = true;

      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "niri/workspaces" ];
        modules-center = [ "niri/window" ];
        modules-right = [
          "tray"
          "clock"
        ];
        "niri/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };
        "niri/window" = {
          format = "{title}";
        };
        tray = {
          spacing = 8;
          icon-size = 18;
        };
        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{:%a, %b %d, %Y}";
        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: sans-serif;
          font-size: 13px;
        }
        window#waybar {
          background-color: rgba(0, 0, 0, 0.75);
        }
        #workspaces button {
          padding: 0 5px;
          background: transparent;
        }
        #workspaces button.active {
          background-color: #4b367c;
        }
        #tray {
          padding: 0 8px;
        }
        #clock {
          padding: 0 10px;
        }
      '';
    };
  };
}
