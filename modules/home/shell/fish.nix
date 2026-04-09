# =============================================================================
# Fish Shell & Terminal Emulator Configuration
# =============================================================================
# Fish shell setup, plugins, and colour-matched configs for Ghostty and Foot.
# All three share the same vague colour palette, so they live together.
# =============================================================================
{ pkgs, colors, ... }:
let
  c = colors.vague;
  h = c.withHash;
in
{
  programs.fish = {
    enable = true;

    shellAbbrs = {
      v = "nvim";
      c = "clear";
      # Uses the system hostname so this works on both desktop and laptop
      # without host-specific abbreviations.
      rebuild = "nh os switch";
      update = "nh os switch --update";
      clean = "nh clean all";
      get-class = "hyprctl clients | grep -A5 'class:'";
      cat = "bat --paging=never --style=plain";
      ls = "eza --group-directories-first --icons=auto";
      ll = "eza -lah --group-directories-first --icons=auto --git";
      lt = "eza --tree --level=2 --icons=auto";
      du = "dust";
      df = "duf";
      ps = "procs";
      find = "fd";
      grep = "rg";
      rga = "ripgrep-all";
      sed = "sd";
      tldr = "tlrc";
      td = "tlrc";
      http = "xh";
      watch = "watchexec";
      gdiff = "git diff";
      j = "just";
    };

    interactiveShellInit = ''
      set -g fish_greeting ""
      set -g fish_autosuggestion_enabled 1

      # Better completion UX: quicker pager response and case-insensitive matching.
      set -g fish_complete_path ""
      set -g fish_pager_color_completion ${c.fg}

      # FZF defaults for faster fuzzy file/history navigation.
      set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
      set -gx FZF_DEFAULT_OPTS "--height=45% --layout=reverse --border --info=inline"
      set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

      if type -q zoxide
          zoxide init fish | source
      end

      if functions -q fzf_configure_bindings
          fzf_configure_bindings --directory=\cf --git_status=\cg --history=\cr --processes=\cp --variables=\cv
      end

      # Ensure consistent history between sessions
      function on_exit --on-event fish_exit
          history merge
      end

      # Fish syntax + completion colors aligned to the Vague palette.
      set -g fish_color_normal ${c.fg}
      set -g fish_color_command ${c.accent}
      set -g fish_color_keyword ${c.purple}
      set -g fish_color_quote ${c.green}
      set -g fish_color_redirection ${c.teal}
      set -g fish_color_end ${c.fgMid}
      set -g fish_color_error ${c.red}
      set -g fish_color_param ${c.fg}
      set -g fish_color_comment ${c.fgDim}
      set -g fish_color_operator ${c.teal}
      set -g fish_color_escape ${c.purple}
      set -g fish_color_autosuggestion ${c.fgDim}
      set -g fish_color_option ${c.yellow}
      set -g fish_color_valid_path ${c.green}
      set -g fish_color_cwd ${c.accent}
      set -g fish_color_cwd_root ${c.red}
      set -g fish_color_user ${c.teal}
      set -g fish_color_host ${c.purple}
      set -g fish_color_host_remote ${c.yellow}
      set -g fish_color_status ${c.red}
      set -g fish_color_selection ${c.fg} --background=${c.bgSubtle}
      set -g fish_color_search_match ${c.accent} --background=${c.bgSubtle}

      set -g fish_pager_color_completion ${c.fg}
      set -g fish_pager_color_description ${c.fgMid}
      set -g fish_pager_color_prefix ${c.accent} --bold
      set -g fish_pager_color_progress ${c.fgDim}
      set -g fish_pager_color_selected_background --background=${c.bgSubtle}
      set -g fish_pager_color_selected_completion ${c.fg}
      set -g fish_pager_color_selected_description ${c.fgMid}
      set -g fish_pager_color_selected_prefix ${c.yellow} --bold

      set -g pure_color_primary  ${c.accent}
      set -g pure_color_info     ${c.purple}
      set -g pure_color_mute     ${c.fgDim}
      set -g pure_color_danger   ${c.red}
      set -g pure_color_warning  ${c.yellow}
      set -g pure_color_success  ${c.green}
    '';

    plugins = with pkgs.fishPlugins; [
      { name = "grc";  src = grc.src;  }
      { name = "z";    src = z.src;    }
      { name = "pure"; src = pure.src; }
      { name = "done"; src = done.src; }
      { name = "fzf"; src = fzf.src; }
      { name = "pisces"; src = pisces.src; }
      { name = "sponge"; src = sponge.src; }
      { name = "forgit"; src = forgit.src; }
    ];
  };

  # ── Ghostty terminal ─────────────────────────────────────────────────────
  xdg.configFile."ghostty/config".text = ''
    command           = ${pkgs.fish}/bin/fish
    font-size         = 12
    cursor-style      = bar
    window-decoration = false
    window-save-state = default
    window-theme      = dark
    clipboard-read    = allow
    clipboard-write   = allow
    background        = ${c.bg}
    foreground        = ${c.fg}
    cursor-color      = ${c.accent}
    selection-background = ${c.selection}
    selection-foreground = ${c.fg}
    palette = 0=${h.bg}
    palette = 1=${h.red}
    palette = 2=${h.green}
    palette = 3=${h.yellow}
    palette = 4=${h.accent}
    palette = 5=${h.purple}
    palette = 6=${h.teal}
    palette = 7=${h.fg}
    palette = 8=${h.bgSubtle}
    palette = 9=${h.red}
    palette = 10=${h.green}
    palette = 11=${h.orange}
    palette = 12=${h.blueBright}
    palette = 13=${h.magenta}
    palette = 14=${h.tealBright}
    palette = 15=${h.fg}
  '';

  # ── Foot terminal ─────────────────────────────────────────────────────────
  xdg.configFile."foot/foot.ini".text = ''
    shell=${pkgs.fish}/bin/fish
    font=JetBrainsMono Nerd Font:size=12
    pad=20x20
    [colors-dark]
    background=${c.bg}
    foreground=${c.fg}
    selection-background=${c.selection}
    selection-foreground=${c.fg}
    regular0=${c.bg}
    regular1=${c.red}
    regular2=${c.green}
    regular3=${c.yellow}
    regular4=${c.accent}
    regular5=${c.purple}
    regular6=${c.teal}
    regular7=${c.fg}
    bright0=${c.bgSubtle}
    bright1=${c.red}
    bright2=${c.green}
    bright3=${c.orange}
    bright4=${c.blueBright}
    bright5=${c.magenta}
    bright6=${c.tealBright}
    bright7=${c.fg}
  '';
}
