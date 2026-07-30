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
          ]
          ++ (with pkgs.unstable; [
            gimp3
          ]);
      };
    };
}
