{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    let
      c = config.theme.colors;
    in
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          spotify
          zathura
          feh
        ];

        hjem.users.${config.username} = {
          files = {
            ".config/feh/themes" = {
              text = ''
                feh --auto-zoom --scale-down --geometry 50%x50%
              '';
            };
            ".config/zathura/zathurarc" = {
              text = ''
                " Auto-reload PDF on file change
                set watch-files true

                " Fit width when opening
                set adjust-open "best-fit"
                set adjust-width "best-fit"
                set adjust-height "best-fit"

                " Inverse search: Ctrl+Click in Zathura opens Neovim at the line
                set synctex-editor-command "nvr --remote-silent +%{line} %{input}"

                " Preferences
                set pages-per-row 1
                set scroll-step 50
                set zoom-min 50
                set zoom-max 400
                set font "monospace 10"
                set window-title-home-tilde true
                set selection-clipboard clipboard

                # Enable dark mode recoloring by default
                set recolor true
                set recolor-keephue true

                # Core layout colors
                set default-bg "#${c.bg}"
                set default-fg "#${c.fg}"
                set recolor-lightcolor "#${c.bg}"
                set recolor-darkcolor "#${c.fg}"

                # Statusbar colors
                set statusbar-bg "#${c.bg}"
                set statusbar-fg "#${c.fg}"

                # Input bar colors
                set inputbar-bg "#${c.bg}"
                set inputbar-fg "#${c.fg}"

                # Notification and error styling
                set notification-bg "#${c.bg}"
                set notification-fg "#${c.fg}"
                set notification-error-bg "#${c.bg}"
                set notification-error-fg "#${c.fg}"
                set notification-warning-bg "#${c.bg}"
                set notification-warning-fg "#${c.fg}"

                # Highlight and selection colors
                set highlight-color "#${c.fgDim}"
                set highlight-active-color "#${c.purple}"

                # Index (Table of Contents) colors
                set index-bg "#${c.bg}"
                set index-fg "#${c.fg}"
                set index-active-bg "#${c.fg}"
                set index-active-fg "#${c.bg}"
              '';
            };
          };
        };
      };
    };
}
