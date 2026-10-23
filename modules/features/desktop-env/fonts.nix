# Desktop fonts.
{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    {
      fonts.packages = with pkgs; [
        inter
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
        nerd-fonts.jetbrains-mono
      ];

      # Use the same family as Kitty so GTK, Qt, XWayland, and Quickshell match
      # the terminal.
      fonts.fontconfig.defaultFonts = {
        monospace = [ config.theme.fonts.monospace ];
        sansSerif = [
          config.theme.fonts.sans
          "Inter"
        ];
        serif = [ config.theme.fonts.serif ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
}
