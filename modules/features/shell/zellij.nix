# =============================================================================
# Zellij Multiplexer Feature
# =============================================================================
# Zellij with tmux-compatible, leader-based interaction and a minimal UI.
#
# Zellij is modal by default (Ctrl+p for panes, Ctrl+t for tabs, ...), which
# collides with editor/readline keybinds. To keep the tmux muscle memory this
# module instead starts Zellij in "locked" mode (everything is passed through to
# the running program) and exposes a single tmux-style leader key (`) that opens
# a dedicated command mode. All tmux binds live there, so the interaction model
# matches tmux rather than Zellij's built-in modes.
#
# The UI is reduced to a single-line compact bar (vs. Zellij's default double
# tab/status bars), hover popups are disabled, and the theme is generated from
# the active `config.theme.colors` palette.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      c = config.theme.colors;

      # Custom status bar plugin (see ./zellij-plugin). zellij's built-in
      # compact-bar hardcodes a "Zellij" label and the raw mode name, and
      # neither it nor zjstatus can show the focused pane's cwd. Building our
      # own tiny wasm plugin gets us the tmux-shaped bar exactly.
      zjbar = pkgs.pkgsCross.wasi32.rustPlatform.buildRustPackage {
        pname = "zjbar";
        version = "0.1.0";
        src = pkgs.lib.cleanSource ./zellij-plugin;
        cargoLock.lockFile = ./zellij-plugin/Cargo.lock;
        nativeBuildInputs = [ pkgs.pkgsCross.wasi32.lld ];
        RUSTFLAGS = "-C linker=wasm-ld";
        doCheck = false;
      };

      # Zellij theme colors are quoted hex strings (e.g. "#cdd6f4").
      hex = x: "\"#${x}\"";

      # A single StyleDeclaration (base/background + 4 emphasis slots).
      mkStyle =
        base: bg: e0: e1: e2: e3:
        "base ${hex base}; background ${hex bg}; emphasis_0 ${hex e0}; emphasis_1 ${hex e1}; emphasis_2 ${hex e2}; emphasis_3 ${hex e3};";

      # Theme generated from the active palette so Zellij matches the rest of
      # the desktop (shell prompt, tmux, bar, etc.).
      zellijTheme = ''
        themes {
          nixos {
            text_unselected {
              ${mkStyle c.fg c.bg c.yellow c.teal c.green c.purple}
            }
            text_selected {
              ${mkStyle c.fg c.bgSubtle c.yellow c.teal c.green c.purple}
            }
            // Tabs: match tmux's window-status.
            //   focused   -> accent on bgSubtle
            //   unfocused -> fgMid on the bar background (draws no block)
            ribbon_selected {
              ${mkStyle c.accent c.bgSubtle c.red c.orange c.purple c.teal}
            }
            ribbon_unselected {
              ${mkStyle c.fgMid c.bg c.red c.orange c.purple c.teal}
            }
            table_title {
              ${mkStyle c.accent c.bg c.yellow c.teal c.green c.purple}
            }
            table_cell_selected {
              ${mkStyle c.fg c.bgSubtle c.yellow c.teal c.green c.purple}
            }
            table_cell_unselected {
              ${mkStyle c.fg c.bg c.yellow c.teal c.green c.purple}
            }
            list_selected {
              ${mkStyle c.fg c.bgSubtle c.yellow c.teal c.green c.purple}
            }
            list_unselected {
              ${mkStyle c.fg c.bg c.yellow c.teal c.green c.purple}
            }
            frame_selected {
              ${mkStyle c.accent c.bg c.yellow c.teal c.green c.purple}
            }
            frame_highlight {
              ${mkStyle c.yellow c.bg c.purple c.yellow c.yellow c.yellow}
            }
            exit_code_success {
              ${mkStyle c.green c.bg c.teal c.bg c.purple c.teal}
            }
            exit_code_error {
              ${mkStyle c.red c.bg c.yellow c.bg c.bg c.bg}
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

      zellijConfig = ''
        // ─── Keybindings ─────────────────────────────────────────────────────
        // clear-defaults wipes Zellij's modal bindings. The leader (backtick)
        // opens a tmux command mode; most actions return to Locked so the very
        // next keystroke goes straight back to the focused program.
        keybinds clear-defaults=true {
          // Default mode: everything reaches the program except the leader.
          locked {
            bind "`" { SwitchToMode "Tmux"; }
          }

          // tmux leader mode (leader = `). Esc / leader twice cancels.
          // Resize actions intentionally stay in this mode so they can repeat
          // (tmux's `bind -r`), exit with Esc.
          tmux {
            bind "Esc" "`" { SwitchToMode "Locked"; }

            // panes: split
            bind "v" "|" { NewPane "Right"; SwitchToMode "Locked"; }
            bind "s" "-" { NewPane "Down"; SwitchToMode "Locked"; }
            bind "\\" { NewPane "Right"; SwitchToMode "Locked"; }
            bind "_" { NewPane "Down"; SwitchToMode "Locked"; }

            // panes: focus
            bind "h" "Left" { MoveFocus "Left"; SwitchToMode "Locked"; }
            bind "j" "Down" { MoveFocus "Down"; SwitchToMode "Locked"; }
            bind "k" "Up" { MoveFocus "Up"; SwitchToMode "Locked"; }
            bind "l" "Right" { MoveFocus "Right"; SwitchToMode "Locked"; }
            bind "q" { FocusNextPane; SwitchToMode "Locked"; }

            // panes: resize (sticky)
            bind "H" { Resize "Increase Left"; }
            bind "L" { Resize "Increase Right"; }
            bind "J" { Resize "Increase Down"; }
            bind "K" { Resize "Increase Up"; }

            // panes: lifecycle & layout
            bind "x" { CloseFocus; SwitchToMode "Locked"; }
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
            // `b` toggles the per-pane borders. With `pane_frames false` below
            // this is NOT tmux's status-bar toggle (zellij has no such action),
            // it simply draws/removes a border row around every pane.
            bind "b" { TogglePaneFrames; SwitchToMode "Locked"; }
            bind "f" { ToggleFloatingPanes; SwitchToMode "Locked"; }
            bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Locked"; }
            bind "m" { ToggleMouseMode; SwitchToMode "Locked"; }
            bind "B" { BreakPane; SwitchToMode "Locked"; }
            bind "y" { ToggleActiveSyncTab; SwitchToMode "Locked"; }
            bind "=" { NextSwapLayout; SwitchToMode "Locked"; }
            bind "{" { MovePane "Left"; SwitchToMode "Locked"; }
            bind "}" { MovePane "Right"; SwitchToMode "Locked"; }
            bind "Ctrl k" { Clear; SwitchToMode "Locked"; }

            // windows (zellij tabs)
            bind "c" "n" { NewTab; SwitchToMode "Locked"; }
            bind "Q" { CloseTab; SwitchToMode "Locked"; }
            bind "[" { GoToPreviousTab; SwitchToMode "Locked"; }
            bind "]" { GoToNextTab; SwitchToMode "Locked"; }
            bind "Tab" { ToggleTab; SwitchToMode "Locked"; }
            bind "1" { GoToTab 1; SwitchToMode "Locked"; }
            bind "2" { GoToTab 2; SwitchToMode "Locked"; }
            bind "3" { GoToTab 3; SwitchToMode "Locked"; }
            bind "4" { GoToTab 4; SwitchToMode "Locked"; }
            bind "5" { GoToTab 5; SwitchToMode "Locked"; }
            bind "6" { GoToTab 6; SwitchToMode "Locked"; }
            bind "7" { GoToTab 7; SwitchToMode "Locked"; }
            bind "8" { GoToTab 8; SwitchToMode "Locked"; }
            bind "9" { GoToTab 9; SwitchToMode "Locked"; }
            bind "<" { MoveTab "Left"; SwitchToMode "Locked"; }
            bind ">" { MoveTab "Right"; SwitchToMode "Locked"; }
            bind "," { SwitchToMode "RenameTab"; TabNameInput 0; }

            // command palette (tmux's `:` command prompt)
            bind ":" {
              LaunchOrFocusPlugin "zjcmd" {
                floating true
                move_to_focused_tab true
              }
              SwitchToMode "Locked"
            }

            // copy / search. tmux parity: `V` enters copy (Scroll) mode,
            // and `/` / `?` start a search prompt.
            bind "V" { SwitchToMode "Scroll"; }
            bind "/" "?" { SwitchToMode "EnterSearch"; SearchInput 0; }

            // sessions
            // (tmux also binds `K` to the sesh picker, but zellij keeps the
            // LAST bind for a key, which silently killed Resize "Increase Up".
            // `w` already opens the session-manager, so `K` stays a resize.)
            bind "d" { Detach; }
            bind "X" { Quit; }
            bind "w" {
              LaunchOrFocusPlugin "session-manager" {
                floating true
                move_to_focused_tab true
              }
              SwitchToMode "Locked"
            }
          }

          // Scrollback / copy mode (leader + V), modelled on tmux copy-mode-vi.
          //
          // NOTE: zellij has no keyboard text selection. There is no
          // BeginSelection / SelectLine / block-select action and therefore no
          // `v`, `V` or `Ctrl v` keybind (zellij-org/zellij#1486, #2840). Text
          // is selected with the mouse -- double-click = word, triple-click =
          // line, drag = range -- and copied automatically because of
          // `copy_on_select true`; `y` below re-copies the active selection.
          // For pure-keyboard selection use `e` (EditScrollback) and copy out
          // of $EDITOR.
          scroll {
            bind "Ctrl c" "Ctrl s" "Esc" "q" { ScrollToBottom; SwitchToMode "Locked"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "g" { ScrollToTop; }
            bind "G" { ScrollToBottom; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
            // tmux copy-mode-vi search: `/` forward, `?` backward, `n` next,
            // `N` previous. Direction is picked with n/N after the query.
            bind "/" "?" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            // tmux `y` (copy-pipe-and-cancel). Safe no-op without a selection.
            bind "y" { Copy; SwitchToMode "Locked"; }
            bind "e" { EditScrollback; SwitchToMode "Locked"; }
            bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "[" { ScrollToPreviousPrompt; }
            bind "]" { ScrollToNextPrompt; }
            bind "m" { SelectCommandAtScrollPosition; }
            bind "c" { CopyLastCommandOutput; SwitchToMode "Locked"; }
          }

          // Search (leader + /). `n`/`N` mirror tmux copy-mode-vi next/prev;
          // `p` is kept as zellij's native "up" alias, `/`/`?` re-prompt.
          search {
            bind "Ctrl c" "Esc" "q" { ScrollToBottom; SwitchToMode "Locked"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "n" { Search "down"; }
            bind "N" "p" { Search "up"; }
            bind "/" "?" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }
          }
          entersearch {
            bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
            bind "Enter" { SwitchToMode "Search"; }
          }

          // Tab rename (leader + ,).
          renametab {
            bind "Ctrl c" "Esc" { UndoRenameTab; SwitchToMode "Locked"; }
            bind "Enter" { SwitchToMode "Locked"; }
          }

          // Pane rename safety. clear-defaults removes the default exits, so
          // add one in case RenamePane is ever triggered (plugin/mouse).
          renamepane {
            bind "Ctrl c" "Esc" { UndoRenamePane; SwitchToMode "Locked"; }
            bind "Enter" { SwitchToMode "Locked"; }
          }

          // Confirmation prompts (kept so dialogs never trap the user).
          prompt {
            bind "y" "Enter" { Confirm; SwitchToMode "Locked"; }
            bind "n" "Esc" { Deny; SwitchToMode "Locked"; }
          }
        }

        // ─── Status bar + command palette plugins ─────────────────────────────
        // Custom plugins (see ./zellij-plugin): zjbar is the tmux-shaped bar,
        // zjcmd is the `leader :` command palette.
        plugins {
          zjbar location="file:${zjbar}/bin/zjbar.wasm" {
            bg        "#${c.bg}"
            fg_mid    "#${c.fgMid}"
            accent    "#${c.accent}"
            bg_subtle "#${c.bgSubtle}"
            yellow    "#${c.yellow}"
            teal      "#${c.teal}"
          }
          zjcmd location="file:${zjbar}/bin/zjcmd.wasm" {
            zellij_bin "${pkgs.zellij}/bin/zellij"
            // floating-window geometry (percent of the viewport)
            x          "20%"
            y          "25%"
            width      "60%"
            height     "50%"
            bg         "#${c.bg}"
            border     "#${c.border}"
            fg         "#${c.fg}"
            fg_mid     "#${c.fgMid}"
            accent     "#${c.accent}"
            bg_subtle  "#${c.bgSubtle}"
          }
        }

        // ─── UI (kept deliberately small, tmux-shaped) ──────────────────────
        // Custom layout: a single status bar pinned to the TOP (see
        // layouts/minimal.kdl + minimal.swap.kdl).
        default_layout "minimal"

        // `simplified_ui` drops the powerline/arrow glyph separators, giving
        // flat rectangular tab blocks like tmux's status bar.
        simplified_ui true

        // No pane frames at all: panes butt right up against each other with
        // no title/border rows eating vertical space. This also keeps tabs
        // numbered (Tab #1, Tab #2, ...), because zellij only swaps a tab's
        // name for the focused pane's terminal title (the running program)
        // when frames are drawn in "titles" mode.
        pane_frames false

        ui {
          pane_frames {
            hide_session_name true
          }
        }

        // Reduce ambient noise: no hover popups / tips or release-notes screen.
        advanced_mouse_actions false
        mouse_hover_effects false
        mouse_hover_tips false
        show_startup_tips false
        show_release_notes false

        // ─── Behaviour ───────────────────────────────────────────────────────
        default_mode "locked"
        default_shell "${pkgs.unstable.fish}/bin/fish"
        mouse_mode true
        scroll_buffer_size 50000
        on_force_close "detach"
        copy_command "${pkgs.wl-clipboard}/bin/wl-copy"
        copy_on_select true
        osc8_hyperlinks true
        session_serialization true

        ${zellijTheme}
      '';
    in
    {
      environment.systemPackages = [
        pkgs.zellij
        pkgs.wl-clipboard
      ];

      # ── Hjem Dotfiles ──────────────────────────────────────────────────────
      hjem.users.${config.username}.files = {
        ".config/zellij/config.kdl" = {
          clobber = true;
          text = zellijConfig;
        };

        # Pre-grant the plugins the permissions they ask for. Without this, the
        # first launch shows zellij's plugin permission prompt, which is awkward
        # to answer for a top-bar plugin (the bar must be focused first). zellij
        # keys the cache by the plugin's absolute path.
        ".cache/zellij/permissions.kdl" = {
          clobber = true;
          text = ''
            "${zjbar}/bin/zjbar.wasm" {
                ReadApplicationState
            }
            "${zjbar}/bin/zjcmd.wasm" {
                ChangeApplicationState
                ReadApplicationState
                RunCommands
            }
          '';
        };

        # Custom layout: single-line status bar pinned to the top.
        ".config/zellij/layouts/minimal.kdl" = {
          clobber = true;
          text = ''
            layout {
                pane size=1 borderless=true {
                    plugin location="zjbar"
                }
                pane
            }
          '';
        };

        # Swap layouts tell zellij how to decorate NEW tabs; without this the
        # status bar would only appear on the first tab.
        ".config/zellij/layouts/minimal.swap.kdl" = {
          clobber = true;
          text = ''
            tab_template name="ui" {
                pane size=1 borderless=true {
                    plugin location="zjbar"
                }
                children
            }

            swap_tiled_layout name="vertical" {
                ui max_panes=4 {
                    pane split_direction="vertical" {
                        pane
                        pane { children; }
                    }
                }
                ui max_panes=7 {
                    pane split_direction="vertical" {
                        pane { children; }
                        pane { pane; pane; pane; pane; }
                    }
                }
                ui max_panes=11 {
                    pane split_direction="vertical" {
                        pane { children; }
                        pane { pane; pane; pane; pane; }
                        pane { pane; pane; pane; pane; }
                    }
                }
            }

            swap_tiled_layout name="horizontal" {
                ui max_panes=3 {
                    pane
                    pane
                }
                ui max_panes=7 {
                    pane {
                        pane split_direction="vertical" { children; }
                        pane split_direction="vertical" { pane; pane; pane; pane; }
                    }
                }
                ui max_panes=11 {
                    pane {
                        pane split_direction="vertical" { children; }
                        pane split_direction="vertical" { pane; pane; pane; pane; }
                        pane split_direction="vertical" { pane; pane; pane; pane; }
                    }
                }
            }

            swap_tiled_layout name="stacked" {
                ui min_panes=3 {
                    pane stacked=true { children; }
                }
            }

            swap_tiled_layout name="half-stacked" {
                ui min_panes=4 {
                    pane split_direction="vertical" {
                        pane
                        pane stacked=true { children; }
                    }
                }
            }

            // Floating swap layouts. Without these, overriding the tiled swap
            // layouts above also wipes zellij's built-in floating layouts, so
            // `=` (NextSwapLayout) does nothing for floating panes.
            swap_floating_layout name="staggered" {
                floating_panes
            }

            swap_floating_layout name="enlarged" {
                floating_panes max_panes=10 {
                    pane { x "5%"; y 1; width "90%"; height "90%"; }
                    pane { x "5%"; y 2; width "90%"; height "90%"; }
                    pane { x "5%"; y 3; width "90%"; height "90%"; }
                    pane { x "5%"; y 4; width "90%"; height "90%"; }
                    pane { x "5%"; y 5; width "90%"; height "90%"; }
                    pane { x "5%"; y 6; width "90%"; height "90%"; }
                    pane { x "5%"; y 7; width "90%"; height "90%"; }
                    pane { x "5%"; y 8; width "90%"; height "90%"; }
                    pane { x "5%"; y 9; width "90%"; height "90%"; }
                    pane { x 10; y 10; width "90%"; height "90%"; }
                }
            }

            swap_floating_layout name="spread" {
                floating_panes max_panes=1 {
                    pane { y "50%"; x "50%"; }
                }
                floating_panes max_panes=2 {
                    pane { x "1%"; y "25%"; width "45%"; }
                    pane { x "50%"; y "25%"; width "45%"; }
                }
                floating_panes max_panes=3 {
                    pane { y "55%"; width "45%"; height "45%"; }
                    pane { x "1%"; y "1%"; width "45%"; }
                    pane { x "50%"; y "1%"; width "45%"; }
                }
                floating_panes max_panes=4 {
                    pane { x "1%"; y "55%"; width "45%"; height "45%"; }
                    pane { x "50%"; y "55%"; width "45%"; height "45%"; }
                    pane { x "1%"; y "1%"; width "45%"; height "45%"; }
                    pane { x "50%"; y "1%"; width "45%"; height "45%"; }
                }
            }
          '';
        };

        # Session picker mirroring the tmux `ta` helper.
        ".config/fish/functions/za.fish" = {
          clobber = true;
          text = ''
            function za --description "Attach to (or start) a zellij session"
                if test (count $argv) -gt 0
                    ${pkgs.zellij}/bin/zellij attach --create $argv[1]
                    return
                end
                set -l sessions (${pkgs.zellij}/bin/zellij list-sessions --short --reverse 2>/dev/null)
                if test -z "$sessions"
                    ${pkgs.zellij}/bin/zellij
                    return
                end
                set -l choice (printf '%s\n' $sessions | ${pkgs.fzf}/bin/fzf --prompt='zellij ❯ ' --height=40% --reverse)
                if test -n "$choice"
                    ${pkgs.zellij}/bin/zellij attach "$choice"
                end
            end
          '';
        };
      };

      # Shell aliases for zellij (avoid `z`, which zoxide owns).
      programs.fish.shellAliases = {
        zj = "zellij";
        zja = "zellij attach";
        zjl = "zellij list-sessions";
        zjk = "zellij kill-session";
        zjd = "zellij delete-session";
      };
    };
}
