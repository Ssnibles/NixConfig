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
    esp32-arduino = {
      path = ../../templates/esp32-arduino;
      description = "ESP32 microcontroller development environment with Arduino CLI, esptool, and LSP support";
    };
  };
}
