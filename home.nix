{ pkgs, ... }:

let
  # Re-run the same battery detection as host-profile.nix. This is simpler
  # than trying to thread the NixOS config into home-manager, and since it's
  # a pure builtins.pathExists check there's no recursion risk.
  hasBat = name: builtins.pathExists "/sys/class/power_supply/${name}/capacity";
  isLaptop = hasBat "BAT0" || hasBat "BAT1";
  isDesktop = !isLaptop;
in
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
    kotlin-language-server
    jdk21
    nixd
    jdt-language-server
    nixpkgs-fmt
    lua-language-server
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
    rPackages.ggplayfair

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

    # --- Misc ---
    flatpak

  ]

  # -------------------------------------------------------------------------
  # DESKTOP-ONLY packages
  # -------------------------------------------------------------------------
  ++ pkgs.lib.optionals isDesktop [

    # --- Gaming ---
    steam
    heroic # GOG / Epic launcher
    lutris # Wine-based game manager
    mangohud # In-game overlay (FPS, GPU temp, etc.)
    gamemode # CPU/GPU optimisation daemon for games
    protonup-qt # Manage Proton-GE versions for Steam

    # --- Desktop utilities ---
    mission-center # System monitor (more useful with a beefy desktop GPU)
    virt-manager # VM management GUI (less common on a laptop)

  ]

  # -------------------------------------------------------------------------
  # LAPTOP-ONLY packages
  # -------------------------------------------------------------------------
  ++ pkgs.lib.optionals isLaptop [

    # --- Power & battery ---
    powertop # Interactive power analysis
    acpi # Battery / AC status from the terminal

    # --- Display ---
    brightnessctl # Already in hyprland keybinds; ensure it's in the profile
    wlsunset # Blue-light filter (less useful on a desktop)

  ];

  # Make the fish shell available to programs that read $SHELL.
  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
  };

  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}

