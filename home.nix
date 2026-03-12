{ config, pkgs, ... }: {

  home.username = "josh";
  home.homeDirectory = "/home/josh";

  # Same rule as system.stateVersion — set once, never touch again.
  home.stateVersion = "25.05";

  # ===========================================================================
  # MODULES
  # Split into separate files to keep things manageable.
  # ===========================================================================
  imports = [
    ./modules/fish.nix # Shell, terminal emulators (foot, ghostty)
    ./modules/hyprland.nix # Window manager, waybar, vicinae
    ./modules/neovim.nix # Editor, plugins, LSP packages
    ./modules/git.nix # Git identity and settings
    ./modules/other.nix # Spotify, Java, miscellaneous
  ];

  # ===========================================================================
  # PACKAGES
  # Add per-user packages here. System-wide packages live in configuration.nix.
  # ===========================================================================
  home.packages = with pkgs; [

    # --- Languages & Dev Tools ---
    kotlin
    kotlin-language-server
    jdk21
    nixd # Nix language server
    jdt-language-server # Java LSP
    nixpkgs-fmt # Nix formatter
    lua-language-server
    code2prompt # Format a codebase for pasting into an LLM

    # --- CLI Utilities ---
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    fzf # Fuzzy finder (used by shell and neovim)
    fd # Fast `find` replacement
    ripgrep # Fast `grep` replacement (used by neovim live grep)
    grc # Generic colouriser for command output
    android-tools # adb, fastboot, etc.
    lazygit # Terminal Git UI
    btop # Resource monitor
    yazi # Terminal file manager

    # --- Fonts ---
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
    nerd-fonts.jetbrains-mono

    # --- GUI Apps ---
    ghostty # Primary terminal emulator
    foot # Fallback terminal emulator
    mission-center # GNOME system monitor
    firefox
    zen-browser # Firefox fork (from flake input)
    sioyek # Keyboard-driven PDF reader
    vnote # Markdown note-taking

    # --- Media ---
    spotify
    strawberry # Music player / library manager
    picard # MusicBrainz tagger
    easytag # Tag editor

    # --- System / Networking ---
    localsend # LAN file sharing (no cloud)
    impala # TUI Wi-Fi manager (uses iwd)
    bluetui # TUI Bluetooth manager
    blueman # GTK Bluetooth manager (for GUI dialogs)
    awww # Efficient animated wallpaper daemon for wayland

    # --- Productivity ---
    super-productivity # To-do / time tracker

    # --- Misc ---
    flatpak # For apps not yet in nixpkgs
  ];

  # Make the fish shell available to programs that read $SHELL.
  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
  };

  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}

