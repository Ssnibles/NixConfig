# Audio and video tools.
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
