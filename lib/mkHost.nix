# =============================================================================
# Host Builder Function
# =============================================================================
# Generates a NixOS system configuration with standard modules, Home Manager
# integration, and host-specific profiles. This abstraction eliminates the
# need to repeat module imports and overlay setup for each host.
#
# Features:
#   • Automatic overlay injection (Neovim nightly, zen-browser, unstable namespace)
#   • Host profile flags (hasNvidia, isLaptop, etc.) available in all modules
#   • Conditional module inclusion (Disko, NVIDIA driver)
#   • Home Manager integration with shared special args
#   • Dual nixpkgs channels (stable system + unstable user packages)
#
# Usage:
#   mkHost {
#     hostName = "desktop";           # Required: host identifier
#     hasNvidia = true;                # Optional: enables nvidia.nix module
#     isLaptop = false;                # Optional: enables TLP, laptop features
#     isVM = false;                    # Optional: VM-specific tweaks
#     useDisko = true;                 # Optional: include Disko partitioning
#     system = "x86_64-linux";         # Optional: system architecture
#     user = "josh";                   # Optional: primary user name
#   }
# =============================================================================
{ inputs, ... }:

let
  inherit (inputs.nixpkgs) lib;
in
{
  mkHost =
    {
      hostName,
      isLaptop ? false,
      hasNvidia ? false,
      isVM ? false,
      useDisko ? true,
      system ? "x86_64-linux",
      user ? "josh",
    }:
    let
      # ── Host Profile ─────────────────────────────────────────────────────
      # Flags accessible via `hostProfile.*` in all NixOS and Home Manager modules
      # Used for conditional logic (e.g., `lib.optionals hostProfile.isLaptop [ ... ]`)
          hostProfile = {
            inherit
              hostName
              isLaptop
              hasNvidia
              isVM
              useDisko
              user
              ;
            isDesktop = !isLaptop; # Convenience flag for desktop-specific config
          };

      # ── Unstable Package Set ─────────────────────────────────────────────
      # Separate evaluation of nixpkgs-unstable for latest user-facing packages
      # Available in modules as `pkgs.unstable.<package>` via overlay
      unstablePkgs = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      nightlyNeovim = inputs.neovim-nightly-overlay.packages.${system}.default;

      # ── Overlays ─────────────────────────────────────────────────────────
      # Inject Neovim nightly and external flake packages into stable pkgs
      overlays = [
        (_final: _prev: {
          # Keep nightly Neovim, but avoid replacing vimPlugins with the nightly
          # overlay plugin set (that can force local plugin builds/checks).
          neovim = nightlyNeovim;
          neovim-unwrapped = nightlyNeovim;

          # Custom packages from flake inputs
          zen-browser = inputs.zen-browser.packages.${system}.default;
          helium = inputs.helium.packages.${system}.default;
          # nix-minecraft overlay (provides fetchModrinthModpack and related tooling)
          nix-minecraft = inputs.nix-minecraft.legacyPackages.${system};

          # Unstable namespace for latest packages
          # Usage in modules: `pkgs.unstable.neovim-unwrapped`
          unstable = unstablePkgs;
        })
      ];
    in
    lib.nixosSystem {
      inherit system;

      # ── Special Arguments ────────────────────────────────────────────────
      # Passed to all NixOS modules (common.nix, host configs, etc.)
      specialArgs = {
        inherit
          inputs         # Access to all flake inputs
          unstablePkgs   # Direct unstable package set (alternative to overlay)
          hostProfile    # Host flags (hasNvidia, isLaptop, etc.)
          user           # Primary user name for user creation
          ;
      };

      # ── Module List ──────────────────────────────────────────────────────
      modules =
        [
          # Overlay injection + hostname
          {
            nixpkgs.overlays = overlays;
            networking.hostName = hostName;
          }

          # Core modules (always included)
          inputs.agenix.nixosModules.default  # Secrets management
          ../modules/nixos/common.nix         # Shared system config
          ../hosts/${hostName}                # Host-specific overrides

          # Home Manager integration
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;      # Use system nixpkgs (with overlays)
              useUserPackages = true;    # Install packages to user profile
              extraSpecialArgs = {       # Pass args to Home Manager modules
                inherit
                  inputs
                  hostProfile
                  user
                  ;
              };
              users.${user} = import ../users/${user}; # User config entry point
            };
          }
        ]
        # Conditional modules (only included if flags are set)
        ++ lib.optional useDisko inputs.disko.nixosModules.disko   # Disk partitioning
        ++ lib.optional useDisko ../disko/${hostName}.nix          # Host-specific layout
        ++ lib.optional hasNvidia ../modules/nixos/hardware/nvidia.nix; # NVIDIA drivers
    };
}
