{ ... }:

{
  services.power-profiles-daemon.enable = false;

  services.fstrim.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 100;
  };
}
