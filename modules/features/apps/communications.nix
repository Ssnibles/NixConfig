# Chat clients.
_: {
  flake.nixosModules.shared =
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
