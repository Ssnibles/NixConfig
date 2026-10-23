# Chat clients.
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          vesktop
          concord-tui
        ];
      };
    };
}
