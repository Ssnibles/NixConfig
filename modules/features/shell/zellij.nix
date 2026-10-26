# Zellij setup.
# Zellij runs in locked mode with a tmux style leader (backtick), one bar row on
# top of every tab, and colours from the active theme. The bar and the leader
# command palette are built from ./zellij-plugin.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      c = config.theme.colours;
      zellijBin = "${pkgs.zellij}/bin/zellij";
      fishBin = "${pkgs.unstable.fish}/bin/fish";

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
      zellijLayout = ''
        layout {
          default_tab_template {
            pane size=1 borderless=true {
              plugin location="zjbar"
            }
            children
          }

          swap_tiled_layout name="vertical" {
            tab max_panes=4 {
              pane split_direction="vertical" {
                pane
                pane { children; }
              }
            }
            tab max_panes=7 {
              pane split_direction="vertical" {
                pane { children; }
                pane { pane; pane; pane; pane; }
              }
            }
            tab max_panes=11 {
              pane split_direction="vertical" {
                pane { children; }
                pane { pane; pane; pane; pane; }
                pane { pane; pane; pane; pane; }
              }
            }
          }

          swap_tiled_layout name="horizontal" {
            tab max_panes=3 {
              pane
              pane
            }
            tab max_panes=7 {
              pane {
                pane split_direction="vertical" { children; }
                pane split_direction="vertical" { pane; pane; pane; pane; }
              }
            }
            tab max_panes=11 {
              pane {
                pane split_direction="vertical" { children; }
                pane split_direction="vertical" { pane; pane; pane; pane; }
                pane split_direction="vertical" { pane; pane; pane; pane; }
              }
            }
          }

          swap_tiled_layout name="stacked" {
            tab min_panes=3 {
              pane stacked=true { children; }
            }
          }

          swap_tiled_layout name="half-stacked" {
            tab min_panes=4 {
              pane split_direction="vertical" {
                pane
                pane stacked=true { children; }
              }
            }
          }

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
        }
      '';

      zellijConfig = ''
        // Keys
        // clear-defaults removes Zellij's own modal bindings. Locked sends
        // every key to the program except the leader, like tmux with a prefix.
        keybinds clear-defaults=true {
          locked {
            bind "`" { SwitchToMode "Tmux"; }
          }

          // Leader. Single step actions return to Locked. Resize and the
          // scroll/search modes stay open so they can repeat.
          tmux {
            // tmux's send-prefix: a doubled leader writes one literal
            // backtick, which keeps nested sessions usable.
            bind "`" { Write 96; SwitchToMode "Locked"; }
            bind "Esc" "Ctrl c" { SwitchToMode "Locked"; }

            // v / | split right, s / - split down. \ and _ are the tmux
            // config aliases for the same two splits.
            bind "v" "|" "\\" { NewPane "Right"; SwitchToMode "Locked"; }
            bind "s" "-" "_" { NewPane "Down"; SwitchToMode "Locked"; }

            bind "h" "Left" { MoveFocus "Left"; SwitchToMode "Locked"; }
            bind "j" "Down" { MoveFocus "Down"; SwitchToMode "Locked"; }
            bind "k" "Up" { MoveFocus "Up"; SwitchToMode "Locked"; }
            bind "l" "Right" { MoveFocus "Right"; SwitchToMode "Locked"; }
            bind "q" { FocusNextPane; SwitchToMode "Locked"; }
            bind ";" { FocusLastPane; SwitchToMode "Locked"; }

            // Resize repeats until Esc.
            bind "H" { Resize "Increase Left"; }
            bind "L" { Resize "Increase Right"; }
            bind "J" { Resize "Increase Down"; }
            bind "K" { Resize "Increase Up"; }

            bind "x" { CloseFocus; SwitchToMode "Locked"; }
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
            bind "b" { TogglePaneFrames; SwitchToMode "Locked"; }
            bind "f" { ToggleFloatingPanes; SwitchToMode "Locked"; }
            bind "E" { TogglePaneEmbedOrFloating; SwitchToMode "Locked"; }
            bind "B" { BreakPane; SwitchToMode "Locked"; }
            bind "y" { ToggleActiveSyncTab; SwitchToMode "Locked"; }
            bind "m" { ToggleMouseMode; SwitchToMode "Locked"; }
            bind "=" { NextSwapLayout; SwitchToMode "Locked"; }
            bind "{" { MovePane "Left"; SwitchToMode "Locked"; }
            bind "}" { MovePane "Right"; SwitchToMode "Locked"; }
            bind "Ctrl k" { Clear; SwitchToMode "Locked"; }

            // Floating yazi rooted at the focused pane's cwd. The bar reads
            // the live cwd and toggles the popup.
            bind "e" {
              MessagePlugin "zjbar" { name "toggle-yazi"; payload ""; }
              SwitchToMode "Locked"
            }

            // Tabs. New tabs inherit the focused pane's cwd, which NewTab
            // cannot do, so the bar opens them.
            bind "c" "n" {
              MessagePlugin "zjbar" { name "new-tab"; payload ""; }
              SwitchToMode "Locked"
            }
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

            // zjcmd is the tmux `:` command prompt, plus a session picker.
            bind ":" {
              LaunchOrFocusPlugin "zjcmd" {
                floating true
                move_to_focused_tab true
              }
              SwitchToMode "Locked"
            }
            bind "S" {
              LaunchOrFocusPlugin "zjcmd" {
                floating true
                move_to_focused_tab true
                picker "sessions"
              }
              SwitchToMode "Locked"
            }

            // Copy / search, modelled on tmux copy-mode-vi.
            bind "V" { SwitchToMode "Scroll"; }
            bind "/" "?" { SwitchToMode "EnterSearch"; SearchInput 0; }

            // Sessions. detach has to reset the mode: zellij keeps the input
            // mode for the session, so a reattach would otherwise land in
            // leader mode.
            bind "d" { Detach; SwitchToMode "Locked"; }
            bind "X" { Quit; }
            bind "w" {
              LaunchOrFocusPlugin "session-manager" {
                floating true
                move_to_focused_tab true
              }
              SwitchToMode "Locked"
            }
          }

          // Scrollback / copy mode (leader + V).
          //
          // Zellij has no keyboard text selection (no BeginSelection or
          // SelectLine action), so v / V / Ctrl v cannot be bound. Text is
          // selected with the mouse and copied by copy_on_select; `y`
          // re-copies the active selection.
          scroll {
            bind "Esc" "Ctrl c" "Ctrl s" "q" { ScrollToBottom; SwitchToMode "Locked"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "g" { ScrollToTop; }
            bind "G" { ScrollToBottom; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
            bind "/" "?" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "y" { Copy; SwitchToMode "Locked"; }
            bind "[" { ScrollToPreviousPrompt; }
            bind "]" { ScrollToNextPrompt; }
            bind "m" { SelectCommandAtScrollPosition; }
            bind "c" { CopyLastCommandOutput; SwitchToMode "Locked"; }
          }

          // Search mode (leader + /, or from scroll mode).
          search {
            bind "Esc" "Ctrl c" "Ctrl s" "q" { ScrollToBottom; SwitchToMode "Locked"; }
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

          // Rename prompts (leader + , and the palette's rename entries).
          renametab {
            bind "Ctrl c" "Esc" { UndoRenameTab; SwitchToMode "Locked"; }
            bind "Enter" { SwitchToMode "Locked"; }
          }
          renamepane {
            bind "Ctrl c" "Esc" { UndoRenamePane; SwitchToMode "Locked"; }
            bind "Enter" { SwitchToMode "Locked"; }
          }

          // Confirmation prompts, so a dialogue can never trap the user.
          prompt {
            bind "y" "Enter" { Confirm; SwitchToMode "Locked"; }
            bind "n" "Esc" { Deny; SwitchToMode "Locked"; }
          }
        }

        // Plugins
        // zjbar draws the bar and handles the leader actions that need the
        // current pane path. zjcmd is the `leader :` command palette.
        plugins {
          zjbar location="file:${zjbar}" {
            bg        "#${c.bg}"
            fg_mid    "#${c.fgMid}"
            accent    "#${c.accent}"
            bg_subtle "#${c.bgSubtle}"
            yellow    "#${c.yellow}"
            teal      "#${c.teal}"
            home        "/home/${config.username}"
            zellij_bin  "${zellijBin}"
            yazi_bin    "${pkgs.yazi}/bin/yazi"
            yazi_x      "7%"
            yazi_y      "7%"
            yazi_width  "86%"
            yazi_height "86%"
          }
          zjcmd location="file:${zjcmd}" {
            zellij_bin "${zellijBin}"
            shell      "${fishBin}"
            setsid_bin "${pkgs.util-linux}/bin/setsid"
            x          "20%"
            y          "25%"
            width      "60%"
            height     "50%"
            bg         "#${c.bg}"
            fg_mid     "#${c.fgMid}"
            accent     "#${c.accent}"
            bg_subtle  "#${c.bgSubtle}"
          }
        }

        // UI
        default_layout "minimal"

        // Flat rectangular tab blocks, like tmux's status bar.
        simplified_ui true

        // No pane frames: panes touch each other and no title row eats space.
        pane_frames false

        // New panes split the focused pane instead of rearranging the tab
        // into a preset swap layout. `=` still cycles the layouts by hand.
        auto_layout false

        // Panes keep their size when the window shrinks, and Ctrl+wheel does
        // not resize them.
        stacked_resize false
        mouse_scroll_resize false

        // Quiet startup and quiet mouse behaviour.
        advanced_mouse_actions false
        mouse_hover_effects false
        mouse_hover_tips false
        show_startup_tips false
        show_release_notes false

        // Behaviour
        default_mode "locked"
        default_shell "${fishBin}"
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
