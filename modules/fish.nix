{ pkgs, ... }: {

  # ===========================================================================
  # FISH SHELL
  # ===========================================================================
  programs.fish = {
    enable = true;

    # Abbreviations expand in-place as you type (better than aliases for
    # discoverability — you can still see and edit the real command).
    shellAbbrs = {
      v = "nvim";
      # Stage everything, then rebuild. The `git add .` ensures new untracked
      # files in the flake directory are included before nixos-rebuild runs.
      rebuild = "git -C ~/NixConfig/ add . && sudo nixos-rebuild switch --flake ~/NixConfig/#nixos";
    };

    # Suppress the default fish greeting.
    interactiveShellInit = ''
      set -g fish_greeting ""
    '';

    plugins = with pkgs.fishPlugins; [
      { name = "grc"; src = grc.src; } # Colourises common command output
      { name = "z"; src = z.src; } # Jump to frecent directories
      { name = "pure"; src = pure.src; } # Minimal async prompt
      { name = "done"; src = done.src; } # Desktop notification when long commands finish
    ];
  };

  # ===========================================================================
  # TERMINAL EMULATORS
  # foot is a lightweight Wayland-native terminal (good fallback).
  # ghostty is the primary terminal.
  # Both are configured to use fish and JetBrains Mono.
  # ===========================================================================

  xdg.configFile."foot/foot.ini".text = ''
    shell=${pkgs.fish}/bin/fish
    font=JetBrainsMono Nerd Font:size=12
    pad=20x20

    [colors]
    background=1E1E2E
    foreground=CDD6F4
  '';

  xdg.configFile."ghostty/config".text = ''
    command         = ${pkgs.fish}/bin/fish
    font-size       = 12
    cursor-style    = bar
    window-decoration = false

    # Restore window size/position across sessions.
    window-save-state = default

    window-theme    = dark

    # Allow clipboard access from within the terminal (e.g. for neovim yank).
    clipboard-read  = allow
    clipboard-write = allow
  '';
}

