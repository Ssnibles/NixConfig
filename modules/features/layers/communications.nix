{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          vesktop
          mumble
        ];
      };

    };
}
