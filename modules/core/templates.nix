# =============================================================================
# Core Flake Templates
# =============================================================================
# Exposes re-usable flake templates exported by this repository.
# =============================================================================
{ ... }:
{
  flake.templates = {
    generic = {
      path = ../../templates/generic;
      description = "A generic dendritic flake using patterns I enjoy";
    };
  };
}
