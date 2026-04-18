# =============================================================================
# Home Manager Entry Point – josh
# =============================================================================
# Applies to every host. Host-specific behaviour is driven by hostProfile
# flags (isDesktop, isLaptop, etc.) inside the individual modules.
#
# All imports here must be Home Manager modules (home.*, programs.*, etc.).
# NixOS-level options belong in modules/nixos/ and hosts/*/configuration.nix.
# =============================================================================
{
  pkgs,
  inputs,
  ...
}:
{
  home = {
    username = "josh";
    homeDirectory = "/home/josh";
    stateVersion = "24.11";
  };

  imports = [
    # Secrets management
    inputs.agenix.homeManagerModules.default
    inputs.stylix.homeModules.stylix
    inputs.nvf.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.spicetify

    # ── Shell & terminal ──────────────────────────────────────────────────
    ../../modules/home/shell/fish.nix
    ../../modules/home/shell/tmux.nix
    ../../modules/home/shell/zellij.nix

    # ── Desktop environment ───────────────────────────────────────────────
    ../../modules/home/desktop/hyprland.nix
    ../../modules/home/desktop/waybar.nix
    ../../modules/home/desktop/swaync.nix

    # ── Editor ────────────────────────────────────────────────────────────
    ../../modules/home/neovim.nix
    ../../modules/home/qutebrowser.nix

    # ── Applications & packages ───────────────────────────────────────────
    ../../modules/home/git.nix
    ../../modules/home/packages.nix
    ../../modules/home/programs.nix
    ../../modules/home/stylix.nix
    ../../modules/home/scripts.nix
  ];

  # ── Cursor ───────────────────────────────────────────────────────────────
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
    QML2_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";
  };

  programs.home-manager.enable = true;
}
