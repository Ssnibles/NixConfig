# Atuin shell history.
# History syncs with the self-hosted server. The sync key and session live in
# ~/.atuin/data, created by `atuin register` or `atuin login`; they are not
# managed here because they are per-machine secrets. The search theme follows
# the active palette.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      c = config.theme.colours;
      theme = config.theme.active;
    in
    {
      environment.systemPackages = [ pkgs.atuin ];

      # Atuin binds Up and Ctrl-R. Fish sources conf.d snippets before the
      # system config, so Atuin loads after fzf-fish and takes Ctrl-R over.
      # AI is disabled because its `?` binding would swallow a bare question
      # mark at an empty prompt, and no AI provider is configured.
      programs.fish.interactiveShellInit = ''
        atuin init fish --disable-ai | source
      '';

      hjem.users.${config.username}.files = {
        # Atuin reads ~/.atuin/config.toml and ignores ~/.config/atuin.
        ".atuin/config.toml".text = ''
          sync_address = "https://atuin.ssnibles.xyz"

          # Enter runs the command, Tab copies it to the prompt for editing.
          enter_accept = true

          # Newest results first, with the query above them.
          invert = true

          # A short panel leaves the shell above it visible.
          inline_height = 20
          inline_height_shell_up_key_binding = 20

          # Drop the tab bar, result numbers, and upgrade note.
          show_tabs = false
          show_numeric_shortcuts = false
          show_whats_new = false

          # One short preview is enough to tell long commands apart.
          show_preview = true
          max_preview_height = 3

          # The query lines up with the command column; duration and time
          # fill the space before it.
          [ui]
          columns = [ "duration", "time", "command" ]
          syntax_highlight = true

          [theme]
          name = "${theme}"
        '';

        # Atuin paints the selected row with AlertError, so that meaning uses
        # the accent colour rather than red.
        ".atuin/themes/${theme}.toml".text = ''
          [theme]
          name = "${theme}"

          [colors]
          Base = "#${c.fg}"
          Important = "#${c.accent}"
          Title = "#${c.purple}"
          Muted = "#${c.fgDim}"
          Annotation = "#${c.fgMid}"
          Guidance = "#${c.teal}"
          AlertInfo = "#${c.green}"
          AlertWarn = "#${c.yellow}"
          AlertError = "#${c.accent}"
          SyntaxCommand = "#${c.fg}"
          SyntaxFlag = "#${c.accent}"
          SyntaxString = "#${c.orange}"
          SyntaxVariable = "#${c.purple}"
          SyntaxOperator = "#${c.fgMid}"
          SyntaxComment = "#${c.fgDim}"
        '';
      };
    };
}
