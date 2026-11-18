{
  pkgs,
  c,
  home,
  zellijBin,
  fishBin,
  zjbar,
  zjcmd,
  zellijTheme,
}:
''
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
      home        "${home}"
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
''
