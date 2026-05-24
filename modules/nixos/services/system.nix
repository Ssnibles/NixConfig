{ pkgs, ... }:

{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/josh/NixConfig";
  };

  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;

  programs.nix-ld.enable = true;

  services.blueman.enable = true;

  hardware.keyboard.qmk = {
    enable = true;
    keychronSupport = true;
  };

  programs.fish.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1week
  '';

  services.gvfs.enable = true;
  services.udisks2.enable = true;
}
