# Desktop and shell UX

## Hyprland highlights

Configured in `modules/home/desktop/hyprland.nix`.

Startup apps:

- wallpaper (`awww`)
- `waybar`
- `nm-applet`
- `swaync`

Core keybinds:

| Key | Action |
|---|---|
| `Super + Enter` | Open terminal (`foot`) |
| `Super + Q` | Close active window |
| `Super + Space` | Toggle Vicinae launcher |
| `Super + N` | Toggle notification center |
| `Super + Delete` | Lock screen (`hyprlock`) |
| `Super + V` | Toggle floating via helper script |
| `Super + G` | Toggle focus mode |
| `Super + S` | Full screenshot to file + clipboard |
| `Super + Shift + S` | Region screenshot to file + clipboard |

Workspace binds are set for `1..10`, plus move/follow and move/silent variants.

## Waybar / SwayNC / Hyprlock

- `waybar.nix`: top bar with workspace/window/clock/media/audio/bluetooth/network/battery
- `swaync.nix`: notifications + control center widgets (`title`, `dnd`, `mpris`, `notifications`)
- `hyprlock.nix`: themed lock screen with time/date labels and centered password field

## Fish shell

Configured in `modules/home/shell/fish.nix`.

### Important abbreviations

| Abbr | Expands to |
|---|---|
| `rebuild` | `nh os switch` |
| `hm` | `nh home switch` |
| `update` | `nh os switch --update` |
| `clean` | `nh clean all` |

Also remaps common commands to modern tools (`ls -> eza`, `cat -> bat`, `grep -> rg`, etc.).

### Fish extras

- `petpick` function + `Alt+p` bind
- `cdf` function for fzf directory jump
- zoxide and fzf integration
- Vague palette colors for Fish + pager

## Terminal multiplexers

- `tmux.nix`: vi-mode tmux with TPM plugins and vim-aware pane navigation
- `zellij.nix`: tmux-like ergonomics with backtick mode and Ctrl+h/j/k/l focus movement
