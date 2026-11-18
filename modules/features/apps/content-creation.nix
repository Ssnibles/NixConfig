# Audio and video tools.
_: {
  flake.nixosModules.shared =
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
