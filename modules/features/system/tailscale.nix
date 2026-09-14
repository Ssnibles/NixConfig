# =============================================================================
# Tailscale Mesh VPN Feature
# =============================================================================
# Secure, zero-config WireGuard mesh network connecting hosts to the tailnet.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      networking.firewall = {
        trustedInterfaces = [ "tailscale0" ];
        allowedUDPPorts = [ config.services.tailscale.port ];
        checkReversePath = "loose";
      };

      environment.systemPackages = [ pkgs.tailscale ];
    };
}
