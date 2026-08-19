# =============================================================================
# Content Creation Applications Feature
# =============================================================================
# Audio/video editing and image design software (Audacity, FFmpeg, GIMP 3).
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      config = {
        environment.systemPackages =
          with pkgs;
          [
            audacity
            ffmpeg
            flac
          ]
          ++ (with pkgs.unstable; [
            gimp3
          ]);
      };
    };
}
