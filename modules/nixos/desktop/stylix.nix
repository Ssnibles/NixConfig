{ ... }:
{
  imports = [ ../../shared/stylix.nix ];

  # Home Manager already imports Stylix in users/josh/default.nix.
  stylix.homeManagerIntegration.autoImport = false;
}
