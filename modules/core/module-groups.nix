# =============================================================================
# Core Module Groups
# =============================================================================
# Declares high-level module options for merging features into hosts.
# =============================================================================
{ lib, ... }:
{
  options.nixos.modules = {
    shared = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = "NixOS module merged into all host configurations.";
    };
    laptop = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = "NixOS module merged into the laptop configuration.";
    };
    desktop = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = "NixOS module merged into the desktop configuration.";
    };
  };
}
