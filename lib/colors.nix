{ colors }:
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

  hexToRgb =
    hex:
    if builtins.stringLength hex < 6 then
      [
        0
        0
        0
      ]
    else
      [
        (hexPairToInt (builtins.substring 0 2 hex))
        (hexPairToInt (builtins.substring 2 2 hex))
        (hexPairToInt (builtins.substring 4 2 hex))
      ];

  palette = rec {
    bg = colors.base00;
    raisedBackground = colors.base01;
    bgRaised = raisedBackground;
    bgSubtle = colors.base02;
    border = colors.base02;

    fg = colors.base05;
    fgMid = colors.base04;
    fgDim = colors.base03;

    accent = colors.base0D;
    teal = colors.base0C;
    purple = colors.base0E;

    green = colors.base0B;
    yellow = colors.base0A;
    red = colors.base08;
    orange = colors.base09;

    magenta = colors.base0F;
    blueBright = colors.base0D;
    tealBright = colors.base0C;

    selection = colors.base02;
    search = colors.base01;
    trailspace = colors.base08;
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
