# Yazi file manager.
# The theme is generated from the active palette so it follows the desktop
# when the scheme changes.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.theme.colours;

      # Templates use @name@ placeholders so the raw config stays in files.
      replacements = {
        "@bg@" = c.bg;
        "@bgRaised@" = c.bgRaised;
        "@border@" = c.border;
        "@fg@" = c.fg;
        "@fgMid@" = c.fgMid;
        "@fgDim@" = c.fgDim;
        "@accent@" = c.accent;
        "@teal@" = c.teal;
        "@purple@" = c.purple;
        "@green@" = c.green;
        "@yellow@" = c.yellow;
        "@red@" = c.red;
      };

      subst =
        file:
        lib.replaceStrings (builtins.attrNames replacements) (builtins.attrValues replacements) (
          builtins.readFile file
        );
    in
    {
      config = {
        environment.systemPackages = [ pkgs.yazi ];

        hjem.users."${config.username}".files = {
          ".config/yazi/yazi.toml".text = builtins.readFile ./yazi/yazi.toml;
          ".config/yazi/keymap.toml".text = builtins.readFile ./yazi/keymap.toml;
          ".config/yazi/theme.toml".text = subst ./yazi/theme.toml.in;
        };
      };
    };
}
