{ inputs, system }:

final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  # ── External flake packages ──────────────────────────────────────────────
  zen-browser = inputs.zen-browser.packages.${system}.default;
  nix-minecraft = inputs.nix-minecraft.legacyPackages.${system};
  solaar = inputs.solaar.packages.${system}.default;
  helium-browser = inputs.helium-browser.packages.${system}.default;

  # ── Built from source (non-flake input) ────────────────────────────────────
  tuxedo = final.rustPlatform.buildRustPackage {
    pname = "tuxedo";
    version = "unstable-2026-06-13";
    src = inputs.tuxedo;
    cargoLock.lockFile = "${inputs.tuxedo}/Cargo.lock";
    doCheck = false;
  };

  # ── Always track unstable channel for these ────────────────────────────────
  neovim = final.unstable.neovim;
  neovim-unwrapped = final.unstable.neovim-unwrapped;
}
