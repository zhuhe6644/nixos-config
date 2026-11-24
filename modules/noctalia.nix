{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  # The LG UltraGear on DP-3. Share its physical mode and logical scale with the greeter.
  display = {
    width = 3840;
    height = 2160;
    refresh_rate = 240.084;
    scale = 1.5;
  };
  cursorTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
  toml = pkgs.formats.toml { };
in
{
  programs.umbriel.enable = true;
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
    systemd = {
      enable = true;
      target = "umbriel-session.target";
    };
    package = pkgs.noctalia.overrideAttrs (prev: {
      # Upstream added the dedicated lock-screen PAM service after 5.5.0.
      patches =
        (prev.patches or [ ])
        ++ lib.optional (prev.version == "5.5.0") (
          pkgs.fetchpatch {
            url = "https://github.com/noctalia-dev/noctalia/commit/806d33fbb356a1fff1ddae1e08932a09790737fd.patch";
            hash = "sha256-rvUjaAWcE5J1LKZELP4//Yroj1EigvILkpQOW3+P1Jw=";
          }
        );
      mesonFlags = prev.mesonFlags ++ [ (lib.mesonOption "pam_service" "noctalia") ];
    });
  };

  services.displayManager = {
    defaultSession = "umbriel";
    noctalia-greeter = {
      enable = true;
      inherit cursorTheme;
      settings = {
        session.default = config.services.displayManager.defaultSession;
        output = display;
      };
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
  };
  environment.systemPackages = [ pkgs.wl-clipboard ];

  home-manager.users.${username} = {
    home.packages = [ pkgs.adwaita-fonts ];
    home.pointerCursor = cursorTheme // {
      enable = true;
      # Match Umbriel's default size in logical pixels.
      size = 24;
    };

    xdg.configFile."umbriel/config.toml".source = toml.generate "umbriel-config.toml" {
      include = {
        files = [ "${config.programs.umbriel.package}/share/umbriel/config.toml" ];
        optional.files = [ "~/.config/umbriel/noctalia.toml" ];
      };
      general.xwayland_native_resolution = true;
      appearance.title_bar.mode = "negotiated";
      hot_corners.top_left.delay_ms = 150;
      output.DP-3 = {
        mode = "${toString display.width}x${toString display.height}@${builtins.toJSON display.refresh_rate}";
        inherit (display) scale;
        hdr = "on";
        sdr_white = 120;
        vrr = "always";
      };
      input = {
        cursor.theme = cursorTheme.name;
        mouse = {
          accel_profile = "flat";
          sensitivity = 0.4;
        };
        touchpad = {
          tap = true;
          natural_scroll = true;
        };
      };
      keybinds = {
        "Mod+Alt+L" = {
          action = "spawn noctalia msg session lock";
          repeat = false;
        };
        Print = {
          action = "spawn noctalia msg screenshot-region";
          repeat = false;
        };
      };
    };

    programs.noctalia = {
      enable = true;
      package = config.programs.noctalia.package;
      settings = {
        shell.polkit_agent = true;
        # Enter starts PAM so the Bio3 can answer an unlock prompt.
        lockscreen.allow_empty_password = true;
        idle.behavior = {
          lock = {
            action = "lock";
            timeout = 900;
            enabled = true;
          };
          screen-off = {
            action = "screen_off";
            timeout = 870;
            locked_timeout = 15;
            enabled = true;
          };
        };
      };
    };
  };
}
