{ lib, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "pnpm-10.29.2"
    ];
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      builders-use-substitutes = true;
      trusted-users = [ "josh" ];
      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nvf.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nvf.cachix.org-1:d1jGkCz8QF7lo4C1m5SwCaLl9TQRHPJ2T/RijAfv0Oc="
      ];
    };
    gc.automatic = lib.mkDefault false;
  };
}
