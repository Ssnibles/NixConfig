{ self, inputs, ... }:
{
  flake.nixosModules.contentCreation =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages =
          with pkgs;
          [
            audacity
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
          ]
          ++ (with pkgs.unstable; [
            chatterino7
            gimp3
          ]);
      };
    };
}
