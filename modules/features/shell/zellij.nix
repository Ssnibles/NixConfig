# Zellij setup.
# Zellij runs in locked mode with a tmux style leader (backtick), one bar row on
# top of every tab, and colours from the active theme. The bar and the leader
# command palette are built from ./zellij-plugin.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      c = config.theme.colours;
      home = config.users.users.${config.username}.home;
      zellijBin = "${pkgs.zellij}/bin/zellij";
      fishBin = "${pkgs.fish}/bin/fish";

      # Plugin permissions are keyed by absolute path, so the config and the
      # permission file below use the same store paths.
      zellijPlugins = pkgs.pkgsCross.wasi32.rustPlatform.buildRustPackage {
        pname = "zellij-plugins";
        version = "0.1.0";
        src = pkgs.lib.cleanSourceWith {
          src = ./zellij-plugin;
          filter = path: _: builtins.baseNameOf path != "target";
        };
        cargoLock.lockFile = ./zellij-plugin/Cargo.lock;
        nativeBuildInputs = [ pkgs.pkgsCross.wasi32.lld ];
        RUSTFLAGS = "-C linker=wasm-ld";
        doCheck = false;
      };
      zjbar = "${zellijPlugins}/bin/zjbar.wasm";
      zjcmd = "${zellijPlugins}/bin/zjcmd.wasm";

      # Zellij theme colours are quoted hex strings.
      hex = x: "\"#${x}\"";

      # One style declaration with a base, a background, and four accents.
      style =
        base: bg: e0: e1: e2: e3:
        "base ${hex base}; background ${hex bg}; emphasis_0 ${hex e0}; emphasis_1 ${hex e1}; emphasis_2 ${hex e2}; emphasis_3 ${hex e3};";

      # Colours come from the active palette so Zellij matches the desktop.
      zellijTheme = ''
        themes {
          nixos {
            text_unselected {
              ${style c.fg c.bg c.yellow c.teal c.green c.purple}
            }
            text_selected {
              ${style c.fg c.bgSubtle c.yellow c.teal c.green c.purple}
            }
            // Focused tab: accent on bgSubtle. Unfocused: fgMid on the bar
            // background, which draws no block.
            ribbon_selected {
              ${style c.accent c.bgSubtle c.red c.orange c.purple c.teal}
            }
            ribbon_unselected {
              ${style c.fgMid c.bg c.red c.orange c.purple c.teal}
            }
            table_title {
              ${style c.accent c.bg c.yellow c.teal c.green c.purple}
            }
            table_cell_selected {
              ${style c.fg c.bgSubtle c.yellow c.teal c.green c.purple}
            }
            table_cell_unselected {
              ${style c.fg c.bg c.yellow c.teal c.green c.purple}
            }
            list_selected {
              ${style c.fg c.bgSubtle c.yellow c.teal c.green c.purple}
            }
            list_unselected {
              ${style c.fg c.bg c.yellow c.teal c.green c.purple}
            }
            frame_selected {
              ${style c.accent c.bg c.yellow c.teal c.green c.purple}
            }
            frame_highlight {
              ${style c.yellow c.bg c.purple c.yellow c.yellow c.yellow}
            }
            exit_code_success {
              ${style c.green c.bg c.teal c.bg c.purple c.teal}
            }
            exit_code_error {
              ${style c.red c.bg c.yellow c.bg c.bg c.bg}
            }
            multiplayer_user_colors {
              player_1 ${hex c.purple};
              player_2 ${hex c.teal};
              player_3 ${hex c.accent};
              player_4 ${hex c.yellow};
              player_5 ${hex c.green};
              player_6 ${hex c.orange};
              player_7 ${hex c.red};
              player_8 ${hex c.fgMid};
              player_9 ${hex c.fgDim};
              player_10 ${hex c.fg};
            }
          }
        }

        theme "nixos"
      '';

      # The bar is a plugin pane, so it has to be part of the tab template. The
      # template applies to the first tab and to every tab opened later.
      #
      # Swap layouts belong in this file. A sibling minimal.swap.kdl is not
      # loaded, which is why the old two-file split left `=` without layouts.
      zellijLayout = builtins.readFile ./zellij/layout.kdl;

      zellijConfig = import ./zellij/_config.nix {
        inherit
          pkgs
          c
          home
          zellijBin
          fishBin
          zjbar
          zjcmd
          zellijTheme
          ;
      };

    in
    {
      environment.systemPackages = [
        pkgs.zellij
      ];

      hjem.users.${config.username}.files = {
        ".config/zellij/config.kdl" = {
          clobber = true;
          text = zellijConfig;
        };

        ".config/zellij/layouts/minimal.kdl" = {
          clobber = true;
          text = zellijLayout;
        };

        # Permissions are keyed by plugin path, so seed them for the exact
        # store paths in the config. The file has to be writable for zellij to
        # save later changes, hence the copy instead of a store symlink.
        ".cache/zellij/permissions.kdl" = {
          clobber = true;
          type = "copy";
          permissions = "644";
          text = ''
            "${zjbar}" {
                ReadApplicationState
                RunCommands
            }
            "${zjcmd}" {
                ChangeApplicationState
                ReadApplicationState
                RunCommands
            }
          '';
        };

        # Session picker, like the tmux ta helper.
        ".config/fish/functions/za.fish" = {
          clobber = true;
          text = ''
            function za --description "Attach to (or start) a zellij session"
                if test (count $argv) -gt 0
                    ${zellijBin} attach --create $argv[1]
                    return
                end
                set -l sessions (${zellijBin} list-sessions --short --reverse 2>/dev/null)
                if test -z "$sessions"
                    ${zellijBin}
                    return
                end
                set -l choice (printf '%s\n' $sessions | ${pkgs.fzf}/bin/fzf --prompt='zellij ❯ ' --height=40% --reverse)
                if test -n "$choice"
                    ${zellijBin} attach "$choice"
                end
            end
          '';
        };
      };

      # Zellij aliases. z is left to zoxide.
      programs.fish.shellAliases = {
        zj = "zellij";
        zja = "zellij attach";
        zjl = "zellij list-sessions";
        zjk = "zellij kill-session";
        zjd = "zellij delete-session";
      };
    };
}
