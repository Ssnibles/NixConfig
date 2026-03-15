# hostProfile is passed in via home-manager.extraSpecialArgs in flake.nix.
# It contains { isLaptop, isDesktop, hasNvidia, isVM } — the same values used
# by the NixOS modules — so laptop/desktop branching works without needing to
# touch the NixOS config from within home-manager's module system.
{
  pkgs,
  hostProfile,
  inputs,
  ...
}:
{
  home.username = "josh";
  home.homeDirectory = "/home/josh";
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
    inputs.agenix.homeManagerModules.default
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
  home.packages =
    with pkgs;
    [
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

      # --- PDF viewers ---
      sioyek
      zathura

      # --- Notes ---
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
      # modrinth-app
      heroic
      lutris
      mangohud
      gamemode
      protonup-qt

      # --- Desktop utilities ---
      virt-manager
    ]
    # -------------------------------------------------------------------------
    # LAPTOP-ONLY packages
    # -------------------------------------------------------------------------
    ++ pkgs.lib.optionals hostProfile.isLaptop [
      # --- Power & battery ---
      powertop
      acpi

      # --- Display ---
      brightnessctl
      wlsunset
    ];

  # Make fish available to programs that read $SHELL.
  home.sessionVariables.SHELL = "${pkgs.fish}/bin/fish";

  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}
