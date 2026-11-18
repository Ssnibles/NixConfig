# Development tools.
# Neovim is configured in apps/neovim.nix.
{
  self,
  ...
}:
{
  flake.nixosModules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          dbeaver-bin

          nodejs
          zig
          gcc
          go

          # Rust. The nixpkgs cargo wrapper carries its own rustc, but
          # rustfmt and clippy are only reachable as cargo subcommands when
          # they are on PATH. sccache stays inert until RUSTC_WRAPPER=sccache.
          cargo
          rustc
          rustfmt
          clippy
          rust-analyzer
          bacon
          cargo-nextest
          cargo-edit
          cargo-expand
          cargo-outdated
          cargo-audit
          cargo-deny
          sccache
          sea-orm-cli
          rustfinity

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
          antigravity-cli
        ];

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
