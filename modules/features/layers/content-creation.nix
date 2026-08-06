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
