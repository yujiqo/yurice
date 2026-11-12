self: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.yurice;

  quickshellConfig = builtins.path {
    name = "yurice-quickshell";
    path = self + "/config/quickshell";
  };

  greeterStart = pkgs.writeShellScript "yurice-greeter-start" ''
    export PATH=${lib.makeBinPath [cfg.greeter.quickshellPackage pkgs.kitty pkgs.greetd config.programs.niri.package]}:$PATH
    ${builtins.replaceStrings ["#!/bin/sh\n" "@greeterQml@"] ["" "${quickshellConfig}/greeter.qml"] (builtins.readFile ../dist/greeter/start.sh)}
  '';

  greeterNiriConfig = pkgs.writeText "yurice-greeter-niri.kdl" (builtins.replaceStrings
    ["@greeterStart@" "@extraConfig@"]
    ["${greeterStart}" cfg.greeter.niriExtraConfig]
    (builtins.readFile ../dist/greeter/niri.kdl));

  greeterSession = pkgs.writeShellScript "yurice-greeter-session" ''
    exec ${config.programs.niri.package}/bin/niri -c ${greeterNiriConfig} >/dev/null 2>&1
  '';

  normalUsers = lib.filterAttrs (_: user: user.isNormalUser) config.users.users;
in {
  options.programs.yurice = {
    enable = lib.mkEnableOption "the system side of the yurice desktop (niri, portals, fonts, qt and gtk integration)";

    greeter = {
      enable = lib.mkEnableOption "the yurice quickshell greeter on greetd";

      quickshellPackage = lib.mkPackageOption pkgs "quickshell" {};

      niriExtraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        example = ''
          output "eDP-1" {
            scale 1
          }
        '';
        description = "Extra niri config for the greeter session, such as output scaling.";
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.greeter.enable -> cfg.enable;
          message = "programs.yurice.greeter needs programs.yurice.enable.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      programs.fish.enable = true;
      programs.niri.enable = true;

      services.pipewire = {
        enable = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
      };
      security.rtkit.enable = lib.mkDefault true;
      services.upower.enable = lib.mkDefault true;
      services.power-profiles-daemon.enable = lib.mkDefault true;
      hardware.bluetooth.enable = lib.mkDefault true;
      networking.networkmanager.enable = lib.mkDefault true;
      programs.dconf.enable = true;
      services.gnome.glib-networking.enable = true;

      fonts.packages = with pkgs; [
        material-symbols
        nerd-fonts.agave
      ];

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
      };

      qt = {
        enable = true;
        platformTheme = "gnome";
        style = "adwaita";
      };
      environment.variables.QT_STYLE_OVERRIDE = lib.mkForce null;
      environment.sessionVariables.QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    })

    (lib.mkIf (cfg.enable && cfg.greeter.enable) {
      services.greetd = {
        enable = true;
        settings.default_session.command = "${greeterSession}";
      };

      systemd.services.greetd.serviceConfig.ExecStartPre = "-${pkgs.writeShellScript "yurice-hide-login-console" (builtins.readFile ../dist/greeter/hide-console.sh)}";

      users.users.greeter = {
        home = "/var/lib/yurice/greeter";
        createHome = false;
      };

      systemd.tmpfiles.rules =
        [
          "d /var/lib/yurice 0755 root root -"
          "d /var/lib/yurice/greeter 0755 greeter greeter -"
          "d /var/lib/yurice/users 0755 root root -"
        ]
        ++ lib.mapAttrsToList (name: user: "d /var/lib/yurice/users/${name} 0755 ${name} ${user.group} -") normalUsers;
    })
  ];
}
