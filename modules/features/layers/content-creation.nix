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
            spek
            ffmpeg
            flac
          ]
          ++ (with pkgs.unstable; [
            gimp3
          ]);
      };
    };
}
