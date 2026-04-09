{
  vague =
    let
      palette = rec {
        bg = "141415";
        raisedBackground = "1c1c24"; # Lighter variant of bg for raised surfaces.
        bgRaised = raisedBackground;
        bgSubtle = "252530";
        border = bgSubtle;

        fg = "cdcdcd";
        fgMid = "878787";
        fgDim = "606079";

        accent = "6e94b2";
        teal = "b4d4cf";
        purple = "bb9dbd";

        green = "7fa563";
        yellow = "f3be7c";
        red = "d8647e";
        orange = "e8b589";

        magenta = "c48282";
        blueBright = "7e98e8";
        tealBright = "9bb4bc";

        selection = "333738";
        search = "2a3a4a";
        trailspace = "3a1c28";
      };
    in
    palette
    // {
      withHash = builtins.mapAttrs (_: value: "#${value}") palette;

      rgb = {
        fg = [
          205
          205
          205
        ];
        bg = [
          20
          20
          21
        ];
        red = [
          216
          100
          126
        ];
        green = [
          127
          165
          99
        ];
        yellow = [
          243
          190
          124
        ];
        blue = [
          110
          148
          178
        ];
        magenta = [
          187
          157
          189
        ];
        orange = [
          243
          190
          124
        ];
        cyan = [
          180
          212
          207
        ];
        black = [
          37
          37
          48
        ];
        white = [
          205
          205
          205
        ];
      };
    };
}
