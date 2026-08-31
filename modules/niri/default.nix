{
  lib,
  pkgs,
  username,
  ...
}:

let
  wallpaper = ./earth.jpg;

  niri = lib.getExe pkgs.niri;
  swaylock = lib.getExe pkgs.swaylock;
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  powerOff = "${niri} msg action power-off-monitors";
  powerOn = "${niri} msg action power-on-monitors";
  isLocked = ''[ "$(${loginctl} show-session auto -p LockedHint --value)" = yes ]'';
  whenLocked = command: "if ${isLocked}; then ${command}; fi";
  whenUnlocked = command: "if ! ${isLocked}; then ${command}; fi";

  # Give the polkit agent its own kdeglobal holding Breeze Dark.
  polkitKdeConfig = pkgs.runCommand "polkit-kde-agent-config" { } ''
    mkdir -p $out
    cp ${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors $out/kdeglobals
  '';
in
{
  imports = [ ./waybar.nix ];

  programs.niri.enable = true;

  # Make Electron/Chromium apps run natively on Wayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    xwayland-satellite # X11 clients under niri
    wl-clipboard
  ];

  home-manager.users.${username} = {
    xdg.configFile."niri/config.kdl".source = ./config.kdl;

    # Application launcher, bound to Mod+D in config.kdl.
    programs.fuzzel.enable = true;

    # Notification daemon.
    services.mako.enable = true;

    programs.swaylock = {
      enable = true;
      settings = {
        show-failed-attempts = true;
        image = wallpaper;
        scaling = "fill";
      };
    };

    services.swayidle = {
      enable = true;
      systemdTargets = [ "niri.service" ];
      timeouts = [
        {
          timeout = 15;
          command = whenLocked powerOff;
          resumeCommand = powerOn;
        }
        {
          timeout = 870;
          command = whenUnlocked powerOff;
          resumeCommand = powerOn;
        }
        {
          timeout = 900;
          command = whenUnlocked "${swaylock} -f";
        }
      ];
      events.before-sleep = whenUnlocked "${swaylock} -f";
    };

    systemd.user.services.dark-color-scheme = {
      Unit = {
        Description = "Prefer a dark colour scheme";
        After = [ "niri.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkgs.dconf} write /org/gnome/desktop/interface/color-scheme \"'prefer-dark'\"";
      };
      Install.WantedBy = [ "niri.service" ];
    };

    # Polkit authentication agent.
    systemd.user.services.polkit-kde-agent = {
      Unit = {
        Description = "Polkit authentication agent";
        PartOf = [ "niri.service" ];
        After = [ "niri.service" ];
      };
      Service = {
        # Set up KDE's Qt theming.
        Environment = [
          "QT_QPA_PLATFORMTHEME=kde"
          "QT_PLUGIN_PATH=${pkgs.kdePackages.plasma-integration}/lib/qt-6/plugins:${pkgs.kdePackages.breeze}/lib/qt-6/plugins"
          "XDG_CONFIG_HOME=${polkitKdeConfig}"
        ];
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "niri.service" ];
    };

    # Wallpaper. Bound to niri.service.
    systemd.user.services.swaybg = {
      Unit = {
        Description = "Wallpaper";
        PartOf = [ "niri.service" ];
        After = [ "niri.service" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.swaybg} --mode fill --image ${wallpaper}";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "niri.service" ];
    };
  };
}
