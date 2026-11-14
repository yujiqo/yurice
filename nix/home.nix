self: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.yurice;
  packages = import ./packages.nix;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  liveCheckout = builtins.isString cfg.configDir;

  link = rel: {recursive ? false}:
    if liveCheckout
    then {
      source = config.lib.file.mkOutOfStoreSymlink "${cfg.configDir}/${rel}";
      force = true;
    }
    else {
      source = cfg.configDir + "/${rel}";
      inherit recursive;
      force = true;
    };

  wallpapers = builtins.path {
    name = "yurice-wallpapers";
    path = self + "/wallpapers";
  };

  noTitlebarButtons = builtins.readFile ../dist/gtk/settings.ini;
in {
  options.programs.yurice = {
    desktop.enable = lib.mkEnableOption "the yurice desktop (niri, quickshell, matugen theming)";

    terminal.enable = lib.mkEnableOption "the yurice terminal setup (kitty, fish, starship, tmux, neovim, lazygit, fastfetch)";

    configDir = lib.mkOption {
      type = lib.types.either lib.types.path lib.types.str;
      default = self + "/config";
      defaultText = lib.literalExpression ''inputs.yurice + "/config"'';
      example = "/home/user/src/yurice/config";
      description = ''
        Where the yurice configs are linked from. A path (the default) links
        immutable copies from the nix store. A string is treated as a mutable
        checkout and linked with mkOutOfStoreSymlink, so edits apply live.
      '';
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.desktop.enable -> isLinux;
          message = "programs.yurice.desktop is Linux only.";
        }
      ];
    }

    (lib.mkIf (cfg.desktop.enable || cfg.terminal.enable) {
      fonts.fontconfig.enable = true;
    })

    (lib.mkIf (cfg.desktop.enable && isLinux) {
      home.packages = packages.desktop pkgs;

      xdg.configFile = {
        "niri" = link "niri" {};
        "quickshell" = link "quickshell" {};
        "matugen" = link "matugen" {};
        "gtk-3.0/settings.ini".text = noTitlebarButtons;
        "gtk-4.0/settings.ini".text = noTitlebarButtons;
      };

      home.activation.yuriceCustomDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -e "${config.xdg.configHome}/yurice/custom" ]; then
          run mkdir -p "${config.xdg.configHome}/yurice/custom"
        fi
      '';

      home.activation.yuriceWallpapers = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${pkgs.runtimeShell} ${../dist/seed-wallpapers.sh} ${wallpapers} "${config.home.homeDirectory}/Pictures/Wallpapers"
      '';

      services.cliphist = {
        enable = true;
        allowImages = true;
      };

      services.polkit-gnome.enable = true;

      dbus.packages = [pkgs.sushi];
      systemd.user.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = "${pkgs.gst_all_1.gst-libav}/lib/gstreamer-1.0";
      xdg.dataFile."sushi/viewers/markdown.js".source = pkgs.replaceVars ../dist/sushi-markdown.js {
        cmark = "${pkgs.cmark-gfm}/bin/cmark-gfm";
      };

      dconf.settings = {
        "org/gnome/desktop/interface".icon-theme = "Adwaita";
        "org/gnome/desktop/wm/preferences".button-layout = ":";
        "org/blueman/general".plugin-list = ["!ConnectionNotifier"];
      };
    })

    (lib.mkIf cfg.terminal.enable {
      home.packages = packages.terminal pkgs;

      xdg.configFile = {
        "kitty/kitty.conf" = link "kitty/kitty.conf" {};
        "kitty/current-theme.conf" = link "kitty/current-theme.conf" {};
        "kitty/kitty.local.conf".text = lib.mkDefault "shell ${pkgs.fish}/bin/fish\n";
        "fish" = link "fish" {recursive = true;};
        "starship.toml" = link "starship/starship.toml" {};
        "tmux" = link "tmux" {recursive = true;};
        "nvim" = link "nvim" {recursive = true;};
        "lazygit" = link "lazygit" {recursive = true;};
        "fastfetch" = link "fastfetch" {};
      };

      home.file.".lesskey" = link "less/key" {};
    })
  ];
}
