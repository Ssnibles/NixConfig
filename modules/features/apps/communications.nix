# Chat clients.
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          vesktop
          concord-tui
        ];
      };
    };
}
