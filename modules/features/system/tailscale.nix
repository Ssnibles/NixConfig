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
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.tailscale;
    in
    {
      options.features.tailscale.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Tailscale mesh VPN client.";
      };

      config = lib.mkIf cfg.enable {
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
    };
}