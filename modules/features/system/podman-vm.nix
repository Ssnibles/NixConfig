# =============================================================================
# Podman Container & Virtualization Feature
# =============================================================================
# OCI container virtualization stack, Docker CLI alias wrapper, and Distrobox.
# =============================================================================
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

      # Disable auto-starting podman daemon on boot (starts socket-activated)
      systemd.services.podman.wantedBy = lib.mkForce [ ];
    };
}
