# =============================================================================
# Content Creation Applications Feature
# =============================================================================
# Audio/video processing tools (FFmpeg, FLAC).
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          ffmpeg
          flac
        ];
      };
    };
}
