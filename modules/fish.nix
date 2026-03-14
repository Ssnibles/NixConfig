{ pkgs, ... }:
{
  # ===========================================================================
  # FISH SHELL
  # Note: programs.fish.enable must also be set in configuration.nix so that
  # fish is added to /etc/shells and available as a login shell.
  # ===========================================================================
  programs.fish = {
    enable = true;

    # Abbreviations expand in-place as you type (better than aliases for
    # discoverability — you can still see and edit the real command).
    shellAbbrs = {
      v = "nvim";

      # rebuild: stages all tracked modifications (but NOT new untracked files)
      # before rebuilding. This avoids the footgun of `git add .` silently
      # staging files you didn't intend to commit.
      #
      # If you have new files you want to include in the flake, stage them
      # manually first with `git add <file>`, then run `rebuild`.
      #
      # The `git add -u` flag updates the index for files already tracked by
      # git (modifications + deletions), which is enough for nixos-rebuild to
      # see your changes without risk of committing stray files.
      rebuild = "echo -n 'Untracked files? Stage with: git add <file>  ' && git -C ~/NixConfig/ add -u && sudo nixos-rebuild switch --flake ~/NixConfig/#nixos";

      # update: refresh all flake inputs then rebuild. Always runs from
      # ~/NixConfig so the flake path is explicit and predictable.
      update = "cd ~/NixConfig && nix flake update && sudo nixos-rebuild switch --flake .";

      get-class = "hyprctl clients | grep -A5 'class:'";
    };

    # Suppress the default fish greeting and apply vague.nvim colours to the
    # pure prompt (https://github.com/pure-fish/pure).
    interactiveShellInit = ''
      set -g fish_greeting ""

      # pure prompt — vague.nvim colours
      set -g pure_color_primary  6e94b2  # keyword  — prompt symbol & cwd
      set -g pure_color_info     bb9dbd  # parameter — git branch
      set -g pure_color_mute     606079  # comment  — command duration / secondary
      set -g pure_color_danger   d8647e  # error    — non-zero exit / git dirty
      set -g pure_color_warning  f3be7c  # warning  — git stash indicator
      set -g pure_color_success  7fa563  # plus     — git clean / ok states
    '';

    plugins = with pkgs.fishPlugins; [
      {
        name = "grc";
        src = grc.src;
      } # Colourises common command output
      {
        name = "z";
        src = z.src;
      } # Jump to frecent directories
      {
        name = "pure";
        src = pure.src;
      } # Minimal async prompt
      {
        name = "done";
        src = done.src;
      } # Desktop notification when long commands finish
    ];
  };

  # ===========================================================================
  # TERMINAL EMULATORS
  # ghostty is the primary terminal; foot is a lightweight Wayland-native
  # fallback (also used as the default terminal in hyprland.nix keybinds).
  # Both are themed with the full vague.nvim 16-colour ANSI palette.
  # ===========================================================================
  xdg.configFile."foot/foot.ini".text = ''
    shell=${pkgs.fish}/bin/fish
    font=JetBrainsMono Nerd Font:size=12
    pad=20x20

    [colors-dark]
    background=141415
    foreground=cdcdcd
    selection-background=333738
    selection-foreground=cdcdcd

    # Normal (0–7)
    regular0=141415
    regular1=d8647e
    regular2=7fa563
    regular3=f3be7c
    regular4=6e94b2
    regular5=bb9dbd
    regular6=b4d4cf
    regular7=cdcdcd

    # Bright (8–15)
    bright0=252530
    bright1=d8647e
    bright2=7fa563
    bright3=e8b589
    bright4=7e98e8
    bright5=c48282
    bright6=9bb4bc
    bright7=cdcdcd
  '';

  xdg.configFile."ghostty/config".text = ''
    command         = ${pkgs.fish}/bin/fish
    font-size       = 12
    cursor-style    = bar
    window-decoration = false
    window-save-state = default
    window-theme    = dark

    # Allow clipboard access from within the terminal (e.g. for neovim yank).
    clipboard-read  = allow
    clipboard-write = allow

    # ── vague.nvim colour palette ──────────────────────────────────────
    background = 141415
    foreground = cdcdcd
    cursor-color = 6e94b2
    selection-background = 333738
    selection-foreground = cdcdcd

    # Normal (0–7)
    palette = 0=#141415
    palette = 1=#d8647e
    palette = 2=#7fa563
    palette = 3=#f3be7c
    palette = 4=#6e94b2
    palette = 5=#bb9dbd
    palette = 6=#b4d4cf
    palette = 7=#cdcdcd

    # Bright (8–15)
    palette = 8=#252530
    palette = 9=#d8647e
    palette = 10=#7fa563
    palette = 11=#e8b589
    palette = 12=#7e98e8
    palette = 13=#c48282
    palette = 14=#9bb4bc
    palette = 15=#cdcdcd
  '';
}
