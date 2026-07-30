{ self, inputs, ... }:
{
  flake.nixosModules.pipewire =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = with pkgs; [
        pulseaudio # Provides pactl
        wireplumber
        pavucontrol
      ];
      # Enable sound with pipewire.
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
