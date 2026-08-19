# =============================================================================
# PipeWire Sound Engine Feature
# =============================================================================
# Modern low-latency sound server replacing PulseAudio, with ALSA and
# 32-bit audio emulation support for gaming.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        pulseaudio # Provides pactl CLI tool
        wireplumber
        pavucontrol
      ];

      # Disable legacy PulseAudio service
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };
}
