{ pkgs, config, semanticColors, ... }:
let
  c = semanticColors { colors = config.lib.stylix.colors; };
  shared = import ./shared.nix;
in
{
  programs.zsh = {
    enable = true;

    enableCompletion = true;

    autosuggestion = {
      enable = true;
      highlight = "fg=${c.withHash.fgDim}";
      strategy = [
        "match_prev_cmd"
        "history"
        "completion"
      ];
    };

    syntaxHighlighting = {
      enable = true;
      styles = {
        default = "none";
        unknown-token = "fg=${c.withHash.red}";
        reserved-word = "fg=${c.withHash.accent}";
        alias = "fg=${c.withHash.accent}";
        builtin = "fg=${c.withHash.accent}";
        function = "fg=${c.withHash.accent}";
        command = "fg=${c.withHash.accent}";
        precommand = "fg=${c.withHash.purple}";
        commandseparator = "fg=${c.withHash.teal}";
        hashed-command = "fg=${c.withHash.accent}";
        path = "fg=${c.withHash.green}";
        path_prefix = "none";
        path_approx = "fg=${c.withHash.orange}";
        globbing = "fg=${c.withHash.teal}";
        history-expansion = "fg=${c.withHash.purple}";
        single-hyphen-option = "fg=${c.withHash.yellow}";
        double-hyphen-option = "fg=${c.withHash.yellow}";
        back-quoted-argument = "fg=${c.withHash.purple}";
        single-quoted-argument = "fg=${c.withHash.green}";
        double-quoted-argument = "fg=${c.withHash.green}";
        dollar-quoted-argument = "fg=${c.withHash.green}";
        back-double-quoted-argument = "fg=${c.withHash.purple}";
        back-dollar-quoted-argument = "fg=${c.withHash.purple}";
        assign = "fg=${c.withHash.fg}";
        redirection = "fg=${c.withHash.teal}";
        comment = "fg=${c.withHash.fgDim}";
        variable = "fg=${c.withHash.fgMid}";
        mathnum = "fg=${c.withHash.teal}";
        named-fd = "fg=${c.withHash.teal}";
        numeric-fd = "fg=${c.withHash.yellow}";
        arg0 = "fg=${c.withHash.accent}";
      };
    };

    history = {
      append = true;
      expireDuplicatesFirst = true;
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      path = "${config.xdg.dataHome}/zsh/history";
      save = 100000;
      share = true;
      size = 100000;
    };

    shellAliases = shared.sharedAliases;

    completionInit = ''
      zstyle ':completion:*' menu select
      zstyle ':completion:*' completer _expand _complete _approximate
      zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' '+l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
    '';

    plugins = [
      {
        name = "forgit";
        src = pkgs.zsh-forgit;
        file = "forgit.plugin.zsh";
      }
      {
        name = "done";
        src = pkgs.done;
        file = "done.zsh";
      }
    ];

    initContent = ''
      setopt AUTO_CD
      setopt COMPLETE_IN_WORD
      setopt CORRECT_ALL
      setopt HIST_VERIFY
      setopt INTERACTIVE_COMMENTS
      setopt NO_BEEP
      setopt PUSHD_IGNORE_DUPS

      function _zsh_set_cursor() {
        case $1 in
          block) printf '\e[2 q';;
          line)  printf '\e[6 q';;
          beam)  printf '\e[4 q';;
        esac
      }
      function zle-line-init() { _zsh_set_cursor line; }
      function zle-keymap-select() {
        case $KEYMAP in
          vicmd) _zsh_set_cursor block;;
          viins|main) _zsh_set_cursor line;;
        esac
      }
      zle -N zle-line-init
      zle -N zle-keymap-select
      _zsh_set_cursor line

      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=120
      ZSH_AUTOSUGGEST_HISTORY_IGNORE="(l[ls]|c[lear]|microfetch|exi[t]|cd\.\.)"

      if (( $+commands[microfetch] )); then
        microfetch
      fi

      if (( $+commands[fd] )); then
        export FZF_DEFAULT_COMMAND="${shared.sharedEnv.FZF_DEFAULT_COMMAND}"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      fi
      export FZF_DEFAULT_OPTS="${shared.sharedEnv.FZF_DEFAULT_OPTS}"
      if (( $+commands[bat] )); then
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
      fi

      if (( $+commands[zoxide] )); then
        eval "$(zoxide init zsh)"
      fi

      if (( $+commands[fzf] )); then
        source <(fzf --zsh)
      fi

      if (( $+commands[grc] )); then
        source ${pkgs.grc}/etc/grc.zsh
      fi

      function petpick() {
        if ! (( $+commands[pet] )); then
          echo "petpick: pet is not installed" >&2
          return 1
        fi
        local selected
        selected="$(pet search --query "$BUFFER")"
        if [[ -n "$selected" ]]; then
          BUFFER="$selected"
          zle reset-prompt
        fi
      }
      zle -N petpick
      bindkey '\ep' petpick

      function mkcd() {
        if [[ $# -eq 0 ]]; then
          echo "mkcd: missing directory name" >&2
          return 1
        fi
        mkdir -p -- "$1" && cd "$1"
      }

      function cdr() {
        local root
        root="$(git rev-parse --show-toplevel 2>/dev/null)"
        if [[ -n "$root" ]]; then
          cd "$root"
          return 0
        fi
        echo "cdr: not inside a git repository" >&2
        return 1
      }

      function cdf() {
        if ! (( $+commands[fd] )) || ! (( $+commands[fzf] )); then
          echo "cdf: fd and fzf are required" >&2
          return 1
        fi
        local search_root="."
        if [[ $# -gt 0 ]]; then
          search_root="$1"
        fi
        if [[ ! -d "$search_root" ]]; then
          echo "cdf: not a directory: $search_root" >&2
          return 1
        fi
        local preview_cmd="ls -la {}"
        if (( $+commands[eza] )); then
          preview_cmd="eza --icons=auto --group-directories-first --git --color=always {}"
        fi
        local target
        target=$(
          { echo "."; fd --type d --hidden --follow --exclude .git . "$search_root" 2>/dev/null; } \
            | fzf --height=45% --layout=reverse --border --prompt="cd > " --preview="$preview_cmd" --preview-window=right,60%,border-left
        )
        if [[ -n "$target" ]]; then
          cd "$target"
        fi
      }

      fpath+=("${pkgs.pure-prompt}/share/zsh/site-functions")
      autoload -U promptinit && promptinit && prompt pure

      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search
      bindkey "^[[B" down-line-or-beginning-search
    '';
  };

  home.packages = with pkgs; [
    pure-prompt
    zsh-forgit
    done
  ];
}
