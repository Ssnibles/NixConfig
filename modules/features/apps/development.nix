# =============================================================================
# Global Development Toolchain & Utilities
# =============================================================================
# Global developer tools, language runtimes, build utilities, and IDEs.
# Note: NVF Neovim distribution packages are defined separately in apps/neovim.nix.
# =============================================================================
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
                [opener]
                edit = [
                  { run = "''${EDITOR:-nvim} \"$@\"", block = true, desc = "Editor" }
                ]
                imv = [
                  { run = "imv-dir \"$@\"", orphan = true, desc = "Open with imv-dir" }
                ]

                [open]
                prepend_rules = [
                  { mime = "image/*", use = "imv" },
                  { mime = "text/*", use = "edit" }
                ]

                [manager]
                show_hidden = true
                sort_by = "natural"
                sort_sensitive = false
                sort_reverse = false
                sort_dir_first = true
                linemode = "size"

                [preview]
                tab_size = 2
                max_width = 1200
                max_height = 1500
                image_filter = "lanczos3"
              '';
            };

            ".config/yazi/keymap.toml" = {
              text = ''
                [mgr]
                prepend_keymap = [
                  { on = [ "." ], run = "hidden toggle", desc = "Toggle hidden files" },
                  { on = [ "T" ], run = "plugin toggle-pane --args=max-preview", desc = "Maximize or restore preview" },
                  { on = [ "e" ], run = "shell 'nvim .' --block", desc = "Open directory in Neovim" },
                ]
              '';
            };
          };
        };
      };
    };
}
