# Development tools.
# Neovim is configured in apps/neovim.nix.
{
  self,
  inputs,
  ...
}:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      pomodoroPkg = lib.optional (
        inputs ? pomodoro
      ) inputs.pomodoro.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      config = {
        environment.systemPackages =
          (with pkgs; [
            dbeaver-bin

            nodejs
            cargo
            zig
            gcc
            go

            # Wayland build headers.
            pkg-config
            wayland
            wlroots
            wayland-protocols
            libxkbcommon
            pixman
            libinput

            # Embedded development.
            arduino-cli
            esptool

            # Command line tools.
            devenv
            yazi
            jujutsu
            jjui
            rclone
            fuse
            sshpass
            sqlite
            self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
          ])
          ++ pomodoroPkg
          ++ (with pkgs.unstable; [
            antigravity-cli
            opencode
            android-studio
          ]);

        hjem.users."${config.username}" = {
          files = {
            ".config/yazi/yazi.toml" = {
              text = ''
                # yazi 25+ uses %s for the path. The old $@ form is no longer
                # replaced, which made Neovim open the current directory.
                [opener]
                edit = [
                  { run = "''${EDITOR:-nvim} %s", block = true, desc = "Edit in $EDITOR" }
                ]
                imv = [
                  { run = "imv-dir %s", orphan = true, desc = "Open images with imv-dir" }
                ]

                [open]
                prepend_rules = [
                  { mime = "image/*", use = "imv" },
                  { mime = "text/*", use = "edit" },
                  { mime = "application/{json,ndjson,javascript,yaml,toml,xml,x-shellscript}", use = "edit" },
                  { mime = "inode/empty", use = "edit" }
                ]

                # The section is [mgr], not [manager], in yazi 25+.
                [mgr]
                linemode = "size"
                show_hidden = true
                show_symlink = true
                sort_by = "natural"
                sort_sensitive = false
                sort_reverse = false
                sort_dir_first = true
                sort_translit = false
                scrolloff = 5
                mouse_events = [ "click", "scroll", "drag" ]

                [preview]
                wrap = "no"
                tab_size = 2
                max_width = 1200
                max_height = 1500
                image_filter = "lanczos3"
                image_quality = 90
              '';
            };

            ".config/yazi/keymap.toml" = {
              text = ''
                [mgr]
                prepend_keymap = [
                  { on = ".", run = "hidden toggle", desc = "Toggle hidden files" },
                  { on = "e", run = "open --hover", desc = "Open hovered file (Neovim for text/code)" },
                  { on = "E", run = "shell 'nvim .' --block", desc = "Open current directory in Neovim" },
                ]
              '';
            };
          };
        };
      };
    };
}
