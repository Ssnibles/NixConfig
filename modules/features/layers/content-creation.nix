{ self, inputs, ... }:
{
  flake.nixosModules.contentCreation =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          audacity
          chatterino7
          spek
          ffmpeg
          flac
          (pkgs.wrapOBS {
            plugins = with pkgs.obs-studio-plugins; [
              wlrobs
              obs-backgroundremoval
              obs-pipewire-audio-capture
              obs-vaapi
              obs-gstreamer
              obs-vkcapture
            ];
          })
        ];
      };
    };
}
