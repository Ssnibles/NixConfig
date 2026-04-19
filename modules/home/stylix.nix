{
  pkgs,
  lib,
  config,
  ...
}:
let
  themeName = import ../../lib/stylix/current-theme.nix;
  themes = import ../../lib/stylix/themes.nix;
  wallpaper = ../../../wallpapers/kalen-emsley-Bkci_8qcdvQ-unsplash.jpg;
  enableUnsupportedProgramExample = false;
  selectedTheme =
    if builtins.hasAttr themeName themes then
      themes.${themeName}
    else
      {
        scheme = "catppuccin-mocha.yaml";
        polarity = "dark";
      };
  hasMatugenTheme = builtins.hasAttr "matugen" selectedTheme;
  matugenConfig = if hasMatugenTheme then selectedTheme.matugen else null;
  matugenMode = if selectedTheme.polarity == "light" then "light" else "dark";
  matugenJson =
    if hasMatugenTheme then
      pkgs.runCommandLocal "matugen-base16-${themeName}.json" { } ''
        set -euo pipefail

        ${pkgs.unstable.matugen}/bin/matugen image ${matugenConfig.wallpaper} \
          --source-color-index ${toString (matugenConfig.sourceColorIndex or 0)} \
          --mode ${matugenMode} \
          --type ${matugenConfig.type or "scheme-tonal-spot"} \
          --json hex \
          --quiet \
          --include-image-in-json=false \
          > "$out"
      ''
    else
      null;
  matugenTheme = if hasMatugenTheme then builtins.fromJSON (builtins.readFile matugenJson) else null;
  matugenScheme =
    if hasMatugenTheme then
      {
        scheme = "Matugen";
        author = "matugen";
        variant = matugenMode;
        base00 = lib.removePrefix "#" matugenTheme.base16.base00.default.color;
        base01 = lib.removePrefix "#" matugenTheme.base16.base01.default.color;
        base02 = lib.removePrefix "#" matugenTheme.base16.base02.default.color;
        base03 = lib.removePrefix "#" matugenTheme.base16.base03.default.color;
        base04 = lib.removePrefix "#" matugenTheme.base16.base04.default.color;
        base05 = lib.removePrefix "#" matugenTheme.base16.base05.default.color;
        base06 = lib.removePrefix "#" matugenTheme.base16.base06.default.color;
        base07 = lib.removePrefix "#" matugenTheme.base16.base07.default.color;
        base08 = lib.removePrefix "#" matugenTheme.base16.base08.default.color;
        base09 = lib.removePrefix "#" matugenTheme.base16.base09.default.color;
        base0A = lib.removePrefix "#" matugenTheme.base16.base0a.default.color;
        base0B = lib.removePrefix "#" matugenTheme.base16.base0b.default.color;
        base0C = lib.removePrefix "#" matugenTheme.base16.base0c.default.color;
        base0D = lib.removePrefix "#" matugenTheme.base16.base0d.default.color;
        base0E = lib.removePrefix "#" matugenTheme.base16.base0e.default.color;
        base0F = lib.removePrefix "#" matugenTheme.base16.base0f.default.color;
      }
    else
      null;
in
{
  # Enable HM program modules so Stylix targets can actually theme them.
  programs = {
    bat = {
      enable = true;
      package = pkgs.unstable.bat;
    };
    fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
    };
    lazygit = {
      enable = true;
      package = pkgs.unstable.lazygit;
    };
    yazi = {
      enable = true;
      package = pkgs.unstable.yazi;
    };
    zathura = {
      enable = true;
      package = pkgs.unstable.zathura;
    };
  };

  xdg.configFile = lib.mkMerge [
    # Take ownership of pre-existing configs on first Stylix migration.
    {
      "lazygit/config.yml".force = true;
    }

    # Example for unsupported programs: render a config file using current
    # Stylix colors. Set enableUnsupportedProgramExample = true to try it.
    (lib.mkIf enableUnsupportedProgramExample {
      "example-app/config.toml".text = ''
        # Example config for apps without a Stylix target
        [theme]
        mode = "${config.lib.stylix.colors.variant}"
        background = "#${config.lib.stylix.colors.base00}"
        foreground = "#${config.lib.stylix.colors.base05}"
        accent = "#${config.lib.stylix.colors.base0D}"
      '';
    })
  ];

  home.file = lib.mkIf hasMatugenTheme {
    ".cache/matugen/colors.jsonc".source = matugenJson;
  };

  assertions = [
    {
      assertion = builtins.hasAttr themeName themes;
      message = ''
        Stylix theme "${themeName}" is not defined in lib/stylix/themes.nix.
      '';
    }
  ];

  stylix = {
    enable = true;
    autoEnable = false;
    image = wallpaper;
    base16Scheme =
      if hasMatugenTheme then
        matugenScheme
      else if builtins.isAttrs selectedTheme.scheme then
        selectedTheme.scheme
      else
        "${pkgs.base16-schemes}/share/themes/${selectedTheme.scheme}";
    polarity = selectedTheme.polarity;

    # Programs in this repo that should follow the currently selected Stylix
    # theme automatically.
    targets = {
      bat.enable = true;
      fzf.enable = true;
      gtk.enable = true;
      lazygit.enable = true;
      qt.enable = true;
      spotify-player.enable = true;
      vicinae.enable = true;
      yazi.enable = true;
      zathura.enable = true;
      "zen-browser".enable = true;
    };
  };
}
