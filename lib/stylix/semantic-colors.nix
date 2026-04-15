{ stylixColors }:
let
  hexDigitValues = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
    "A" = 10;
    "B" = 11;
    "C" = 12;
    "D" = 13;
    "E" = 14;
    "F" = 15;
  };

  hexPairToInt =
    pair:
    (hexDigitValues.${builtins.substring 0 1 pair} * 16)
    + hexDigitValues.${builtins.substring 1 1 pair};

  hexToRgb = hex: [
    (hexPairToInt (builtins.substring 0 2 hex))
    (hexPairToInt (builtins.substring 2 2 hex))
    (hexPairToInt (builtins.substring 4 2 hex))
  ];

  palette = rec {
    bg = stylixColors.base00;
    raisedBackground = stylixColors.base01;
    bgRaised = raisedBackground;
    bgSubtle = stylixColors.base02;
    border = stylixColors.base02;

    fg = stylixColors.base05;
    fgMid = stylixColors.base04;
    fgDim = stylixColors.base03;

    accent = stylixColors.base0D;
    teal = stylixColors.base0C;
    purple = stylixColors.base0E;

    green = stylixColors.base0B;
    yellow = stylixColors.base0A;
    red = stylixColors.base08;
    orange = stylixColors.base09;

    magenta = stylixColors.base0F;
    blueBright = stylixColors.base0D;
    tealBright = stylixColors.base0C;

    selection = stylixColors.base02;
    search = stylixColors.base01;
    trailspace = stylixColors.base08;
  };
in
palette
// {
  withHash = builtins.mapAttrs (_: value: "#${value}") palette;

  rgb = {
    fg = hexToRgb palette.fg;
    bg = hexToRgb palette.bg;
    red = hexToRgb palette.red;
    green = hexToRgb palette.green;
    yellow = hexToRgb palette.yellow;
    blue = hexToRgb palette.accent;
    magenta = hexToRgb palette.purple;
    orange = hexToRgb palette.orange;
    cyan = hexToRgb palette.teal;
    black = hexToRgb palette.bgSubtle;
    white = hexToRgb palette.fg;
  };
}
