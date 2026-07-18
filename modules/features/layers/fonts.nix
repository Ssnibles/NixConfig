{ self, inputs, ... }:
{
  flake.nixosModules.fonts =
    { pkgs, lib, ... }:
    {
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        nerd-fonts.martian-mono
        dina-font
        proggyfonts
        ripgrep
      ];
    };
}
