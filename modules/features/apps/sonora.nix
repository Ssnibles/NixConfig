# Sonora music client.
# The upstream module wraps the binary for WebKit, GStreamer and ALSA, and
# sets programs.sonora.package from the flake input. Cached at
# https://sonora.cachix.org, added in system/base.nix.
{ inputs, ... }:
{
  flake.nixosModules.shared =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.sonora;
    in
    {
      imports = [ inputs.sonora.nixosModules.default ];

      options.features.sonora.enable = lib.mkEnableOption "the Sonora music client";

      config = lib.mkIf cfg.enable {
        programs.sonora.enable = true;
      };
    };
}
