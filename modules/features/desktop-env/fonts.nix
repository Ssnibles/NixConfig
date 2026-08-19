# =============================================================================
# Desktop Environment Fonts Feature
# =============================================================================
# Provides system UI typography (Inter, Noto), serif, and monospace Nerd Fonts.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        inter
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
        nerd-fonts.jetbrains-mono
      ];
    };
}
