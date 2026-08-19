{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      ...
    }:
    {
      virtualisation = {
        containers.enable = true;

        podman = {
          enable = true;

          dockerCompat = true;
        };
      };

      environment.systemPackages = with pkgs; [
        podman-compose
        distrobox
        boxbuddy
      ];

      systemd.services.podman.wantedBy = lib.mkForce [ ];
    };
}
