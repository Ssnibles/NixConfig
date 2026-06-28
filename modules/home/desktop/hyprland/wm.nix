{
  pkgs,
  lib,
  config,
  hostProfile,
  semanticColors,
  ...
}:
let
  screenshotDir = "~/Pictures/Screenshots";
  sattyFocusCommand = "(sleep 0.15 && (hyprctl dispatch 'hl.dsp.focus({window = \"class:^(satty)$\"})' || hyprctl dispatch 'hl.dsp.focus({window = \"class:^(com\\.gabm\\.satty)$\"})'))";
  sattyCaptureCommand = "satty --disable-notifications --filename - --output-filename \"${screenshotDir}/Screenshot-%Y-%m-%d_%H-%M-%S.png\" --copy-command wl-copy --actions-on-enter save-to-file,save-to-clipboard,exit";
  c = semanticColors { colors = config.lib.stylix.colors; };
  wallpaper = (import ../../../../lib/stylix/themes.nix).wallpaper;
  hyprDir = "${config.home.homeDirectory}/NixConfig/modules/home/desktop/hyprland";

  generatedLua = ''
    local M = {}

    -- Colors from Stylix
    M.accent = "${c.accent}"
    M.border = "${c.border}"
    M.accent_hash = "#${c.accent}"
    M.border_hash = "#${c.border}"

    -- Host profile
    M.isDesktop = ${if hostProfile.isDesktop then "true" else "false"}
    M.isLaptop = ${if hostProfile.isLaptop then "true" else "false"}
    M.hasNvidia = ${if hostProfile.hasNvidia then "true" else "false"}

    -- Paths
    M.wallpaper = "${builtins.toString wallpaper}"
    M.screenshot_dir = "${screenshotDir}"

    -- Screenshot commands
    M.satty_focus = [[${sattyFocusCommand}]]
    M.satty_capture = [[${sattyCaptureCommand}]]

    -- Special workspace name
    M.special_workspace = "special"

    return M
  '';
in
{
  home.packages = with pkgs; [
    libnotify
    networkmanagerapplet
    playerctl
    adwaita-icon-theme
  ];

  xdg.configFile."hypr/xdph.conf".text = lib.concatStrings [
    ''
      screencopy {
          max_fps = 60
    ''
    (lib.optionalString hostProfile.hasNvidia "    force_shm = true\n")
    ''
      }
    ''
  ];

  programs.vicinae.enable = true;

  xdg.configFile."vicinae/settings.json" = {
    force = true;
    text = builtins.toJSON {
      search_files_in_root = false;
      pixmap_cache_mb = 128;
      launcher_window = {
        opacity = 1.0;
        blur = {
          enabled = false;
        };
      };
      theme = {
        dark = {
          name = "stylix";
        };
        light = {
          name = "stylix";
        };
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "lua";
    extraConfig = "-- see symlinked hyprland.lua";
  };

  # Write generated values into the repo so mkOutOfStoreSymlink can pick them up
  home.file."NixConfig/modules/home/desktop/hyprland/generated.lua" = {
    text = generatedLua;
    force = true;
  };

  xdg.configFile."hypr/hyprland.lua" = lib.mkForce {
    source = config.lib.file.mkOutOfStoreSymlink "${hyprDir}/hyprland.lua";
  };

  xdg.configFile."hypr/generated.lua" = lib.mkForce {
    source = config.lib.file.mkOutOfStoreSymlink "${hyprDir}/generated.lua";
  };
}
