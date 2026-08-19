# =============================================================================
# Communication Applications Feature
# =============================================================================
# Messaging and chat clients (Vesktop / Discord client).
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          vesktop
        ];
      };
    };
}
