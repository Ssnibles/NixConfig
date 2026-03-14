# hostProfile is passed in via home-manager.extraSpecialArgs in flake.nix.
# It contains { isLaptop, isDesktop, hasNvidia } — the same values used by
# the NixOS modules — so laptop/desktop branching works without needing to
# touch the NixOS config from within home-manager's module system.
{ pkgs, hostProfile, ... }:

{
  home.username = "josh";
  home.homeDirectory = "/home/josh";

  # Same rule as system.stateVersion — set once, never touch again.
  home.stateVersion = "25.05";

  # ===========================================================================
  # MODULES
  # ===========================================================================
  imports = [
    ./modules/fish.nix
    ./modules/hyprland.nix
    ./modules/neovim.nix
    ./modules/git.nix
    ./modules/other.nix
    ./modules/waybar.nix
    ./modules/swaync.nix
  ];

  # ===========================================================================
  # CURSOR
  # ===========================================================================
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # ===========================================================================
  # PACKAGES
  # ===========================================================================
  home.packages = with pkgs; [

    # -------------------------------------------------------------------------
    # SHARED — installed on both laptop and desktop
    # -------------------------------------------------------------------------

    # --- Languages & Dev Tools ---
    kotlin
    jdk21
    code2prompt

    # --- CLI Utilities ---
    wl-clipboard
    fzf
    fd
    ripgrep
    grc
    android-tools
    lazygit
    btop
    yazi

    # --- Fonts ---
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
    nerd-fonts.jetbrains-mono

    # --- GUI Apps ---
    ghostty
    foot
    mission-center
    firefox
    zen-browser
    sioyek
    kdePackages.okular
    zathura
    vnote
    trilium-desktop

    # --- Media ---
    spotify
    strawberry
    picard
    easytag
    pavucontrol

    # --- System / Networking ---
    localsend
    impala
    bluetui
    blueman

  ]

  # -------------------------------------------------------------------------
  # DESKTOP-ONLY packages
  # -------------------------------------------------------------------------
  ++ pkgs.lib.optionals hostProfile.isDesktop [

    # --- Gaming ---
    steam
    heroic # GOG / Epic launcher
    lutris # Wine-based game manager
    mangohud # In-game overlay (FPS, GPU temp, etc.)
    gamemode # CPU/GPU optimisation daemon for games
    protonup-qt # Manage Proton-GE versions for Steam

    # --- Desktop utilities ---
    virt-manager # VM management GUI (less common on a laptop)

  ]

  # -------------------------------------------------------------------------
  # LAPTOP-ONLY packages
  # -------------------------------------------------------------------------
  ++ pkgs.lib.optionals hostProfile.isLaptop [

    # --- Power & battery ---
    powertop # Interactive power analysis
    acpi # Battery / AC status from the terminal

    # --- Display ---
    brightnessctl # Already in hyprland keybinds; ensure it's in the profile
    wlsunset # Blue-light filter (less useful on a desktop)

  ];

  # Make fish available to programs that read $SHELL.
  home.sessionVariables.SHELL = "${pkgs.fish}/bin/fish";

  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}
