# =============================================================================
# Primary User Account Feature
# =============================================================================
# Configuration for primary user account (`josh`), system groups, and Hjem home engine.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      config,
      ...
    }:
    {
      # System groups
      users.groups.plugdev = { };

      # Primary user account definition
      users.users.${config.username} = {
        isNormalUser = true;
        description = "${config.username} user account";
        extraGroups = [
          "networkmanager"
          "wheel"
          "plugdev"
          "dialout"
        ];
      };

      # Hjem user configuration root
      hjem.users.${config.username} = {
        enable = true;
        clobberFiles = true;
      };

      # Hjem's `update-state` action shells out to `nix-store` to register GC
      # roots for the files it manages. The unit Hjem generates ships only a
      # minimal PATH (coreutils/findutils/grep/sed/systemd), so `nix-store` is
      # not found and Hjem logs
      #   "WARN nix-store is unavailable; skipping state GC roots"
      # on every activation, silently leaving the managed store paths
      # unrooted. Put Nix on the unit PATH so the roots are actually pinned.
      systemd.services."hjem-update-state@".path = [ config.nix.package ];
    };
}
