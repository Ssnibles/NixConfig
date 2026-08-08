{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          spotify
          zathura
        ];

        hjem.users.${config.username} = {
          files = {
            ".config/zathura/zathurarc" = {
              text = ''
                " Auto-reload PDF on file change
                set watch-files true

                " Fit width when opening
                set adjust-open "best-fit"

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
              '';
            };
          };
        };
      };
    };
}
