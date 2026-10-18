# Desktop Environment Fonts Feature
# Provides system UI typography (Inter, Noto), serif, and monospace Nerd Fonts.
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

      # Match the fonts chosen via `theme.fonts`: monospace is the same family
      # Kitty uses, so GTK/Qt/XWayland agree with the terminal and Quickshell.
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
