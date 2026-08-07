{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        inter
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        nerd-fonts.martian-mono
        nerd-fonts.jetbrains-mono
        dina-font
        proggyfonts
      ];
    };
}
