# Global Development Toolchain & Utilities
# Global developer tools, language runtimes, build utilities, and IDEs.
# Note: NVF Neovim distribution packages are defined separately in apps/neovim.nix.
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
          with pkgs;
          [
            # Editors & AI tools
            pkgs.unstable.antigravity-cli
            pkgs.unstable.opencode
            dbeaver-bin

            # Runtimes & Compilers
            nodejs
            cargo
            zig
            gcc
            go

            # Wayland build headers
            pkg-config
            wayland
            wlroots
            wayland-protocols
            libxkbcommon
            pixman
            libinput

            # Embedded & Microcontroller Dev
            arduino-cli
            esptool

            # CLI Dev Utilities
            devenv
            yazi
            jujutsu
            jjui
            rclone
            fuse
            sshpass
            sqlite
            self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
          ]
          ++ pomodoroPkg
          ++ (with pkgs.unstable; [
            android-studio
          ]);

        hjem.users."${config.username}" = {
          files = {
            ".config/yazi/yazi.toml" = {
              text = ''
                # yazi 25+ uses `%s` (and `%s1`, `%S`, ...) as the path
                # placeholder. The old `$@` form is no longer substituted,
                # which made Neovim open the *cwd* instead of the file.
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

                # NOTE: the section is `[mgr]`, not `[manager]`, in yazi 25+.
                # Everything under the old name was silently ignored.
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
