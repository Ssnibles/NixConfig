# =============================================================================
# Home Manager Configuration
# =============================================================================
# User-specific settings applied to all hosts.
# Imports modules for shell, WM, editor, etc.
#
# IMPORTANT: All modules imported here must be Home Manager modules.
# They should use 'home.*' options, not NixOS options.
# =============================================================================
{
  pkgs,
  hostProfile,
  inputs,
  ...
}:
{
  # Home Manager user configuration
  home = {
    username = "josh";
    homeDirectory = "/home/josh";
    stateVersion = "25.05";
  };

  # Import Home Manager modules
  # These modules must use Home Manager options (home.*, programs.*, etc.)
  imports = [
    # Secrets management
    inputs.agenix.homeManagerModules.default
    # User environment modules
    ../../modules/fish.nix
    ../../modules/hyprland.nix
    ../../modules/neovim.nix
    ../../modules/git.nix
    ../../modules/packages.nix
    ../../modules/waybar.nix
    ../../modules/swaync.nix
    ../../modules/other.nix
    ../../modules/scripts.nix
    ../../modules/tmux.nix
  ];

  # Pointer cursor configuration
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Shell environment variable
  home.sessionVariables.SHELL = "${pkgs.fish}/bin/fish";

  # Enable Home Manager itself
  programs.home-manager.enable = true;
}
