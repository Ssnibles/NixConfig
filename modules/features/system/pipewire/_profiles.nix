{ pkgs }:
{
  # https://github.com/jaakkopasanen/AutoEq/tree/master/results/Harpo/in-ear/Moondrop%20Aria%202
  aria2 = {
    sink = "eq_aria2";
    description = "Aria 2 EQ";
    match = [
      "moondrop"
      "dawn pro"
    ];
    curve = pkgs.writeText "moondrop-aria2-parametric-eq.txt" ''
      Preamp: -4.4 dB
      Filter 1: ON LSC Fc 105 Hz Gain 1.7 dB Q 0.70
      Filter 2: ON PK Fc 159 Hz Gain -3.2 dB Q 0.64
      Filter 3: ON PK Fc 7000 Hz Gain 3.5 dB Q 1.20
      Filter 4: ON PK Fc 773 Hz Gain 2.4 dB Q 0.93
      Filter 5: ON PK Fc 1802 Hz Gain -1.2 dB Q 0.91
      Filter 6: ON HSC Fc 10000 Hz Gain -1.0 dB Q 0.70
      Filter 7: ON PK Fc 4551 Hz Gain -1.5 dB Q 4.73
      Filter 8: ON PK Fc 6036 Hz Gain 1.9 dB Q 5.44
      Filter 9: ON PK Fc 7146 Hz Gain -0.9 dB Q 6.00
      Filter 10: ON PK Fc 3343 Hz Gain 0.6 dB Q 4.19
    '';
  };

  # https://github.com/jaakkopasanen/AutoEq/tree/master/results/oratory1990/over-ear/Sennheiser%20HD%20450BT
  hd450bt = {
    sink = "eq_hd450bt";
    description = "HD 450BT EQ";
    match = [
      "hd 450"
      "450bt"
    ];
    curve = pkgs.writeText "sennheiser-hd450bt-parametric-eq.txt" ''
      Preamp: -6.4 dB
      Filter 1: ON LSC Fc 105 Hz Gain -2.7 dB Q 0.70
      Filter 2: ON PK Fc 2417 Hz Gain -4.2 dB Q 0.56
      Filter 3: ON PK Fc 3855 Hz Gain 8.3 dB Q 1.65
      Filter 4: ON PK Fc 151 Hz Gain -3.0 dB Q 1.14
      Filter 5: ON PK Fc 6571 Hz Gain 3.5 dB Q 1.15
      Filter 6: ON HSC Fc 10000 Hz Gain 5.6 dB Q 0.70
      Filter 7: ON PK Fc 8215 Hz Gain -2.8 dB Q 4.27
      Filter 8: ON PK Fc 374 Hz Gain 0.9 dB Q 2.79
      Filter 9: ON PK Fc 656 Hz Gain -0.6 dB Q 2.31
      Filter 10: ON PK Fc 41 Hz Gain -0.2 dB Q 1.75
    '';
  };
}
