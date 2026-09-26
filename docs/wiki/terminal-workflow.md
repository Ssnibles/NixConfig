# Terminal Workflow: Kitty, Tmux, Yazi, Pet & Shell Environment

This guide documents the terminal environment in NixConfig, covering the Kitty terminal emulator, Tmux multiplexer, Yazi file manager, Pet snippet picker, and the Fish shell with Starship prompt.

---

## Overview

The terminal environment is engineered for low latency, memory efficiency, and fast navigation:

| Layer | Component | Key Highlights | Configuration File |
| :--- | :--- | :--- | :--- |
| **Terminal** | **Kitty** | Single-instance server mode, shared GPU sprite cache, Maple Mono font | `modules/features/apps/kitty.nix` |
| **Alternative** | **Foot** | Lightweight Wayland native terminal | `modules/packages/foot/default.nix` |
| **Multiplexer** | **Tmux** | Backtick prefix, Sesh session picker, resurrect path sanitizer, floating popups | `modules/features/shell/tmux.nix` |
| **File Manager** | **Yazi** | Async Rust file manager, image previews, Neovim directory opening | `modules/features/apps/development.nix` |
| **Snippets** | **Pet** | Fuzzy command snippet insertion bound to `Ctrl+P` | `modules/packages/pet/default.nix` |
| **Shell** | **Fish 4+** | 5-minute cached FZF search (`__fzf_cache_fd`), Starship prompt | `modules/features/shell/shell.nix` |

---

## Kitty Terminal Emulator

Kitty is the default terminal emulator across all hosts, configured with optimisations for memory conservation and Wayland integration.

### Single-Instance Server Mode

By default, opening multiple terminal windows typically spawns separate processes, each allocating duplicate GPU texture memory and font caches. In NixConfig:

- Kitty runs in **single-instance server mode** via the `kitty --single-instance` flag (used in desktop launchers, compositor window bindings, and scripts).
- `allow_remote_control socket-only` enables a secure Unix domain socket, allowing new windows to attach to the running process without opening terminal control to internal processes.
- Memory consumption per additional window is drastically reduced because all windows share a single GPU texture cache.

### Memory & Performance Capping

- **Scrollback Buffer**: Capped to 2,000 lines (`scrollback_lines 2000`). Separate pager scrollback history buffer is disabled (`scrollback_pager_history_size 0`) to prevent RAM bloat during long sessions.
- **Image Cache Limit**: Capped to 16 MB (`max_image_bytes 16777216`), keeping the kitty graphics protocol cache lean.
- **Rendering**: Canvas max size set to 4096, synced to monitor refresh rate. Audio bell disabled.

### Styling & Typography

- **Font**: Maple Mono (`Maple Mono NR NF`) at 12pt, with block cursor and 10px horizontal/vertical padding.
- **Palette Tokens**: All 16 ANSI colours and window backgrounds (`bg`, `fg`, `accent`, `border`, `selection`) are generated dynamically from the active theme palette (`config.theme.colors`).

---

## Tmux Multiplexer & Session Management

Tmux is managed via `modules/features/shell/tmux.nix` and runs as an automated systemd user daemon (`tmux.service`), keeping sessions alive across graphical logout or compositor restarts.

### Core Configuration

- **Prefix Key**: Backtick (`` ` ``). Pressing backtick twice sends a literal backtick.
- **Base Index**: 1 (windows and panes start counting at 1 instead of 0).
- **Default Shell**: Unstable Fish 4+.
- **Vi Mode**: Full vi keybindings enabled in copy mode and status line.

### Sesh Session Manager

Tmux integrates with [Sesh](https://github.com/joshmedeski/sesh) for smart session switching:

- **`Prefix + K`**: Opens a floating interactive popup (`tmux-sesh-picker`) powered by FZF:
  - `Ctrl+A`: Show all sessions
  - `Ctrl+T`: Show active Tmux sessions
  - `Ctrl+G`: Show configuration directories
  - `Ctrl+X`: Show Zoxide directory history
  - `Ctrl+F`: Find Git repositories under home directory
  - `Ctrl+D`: Kill selected session or remove Zoxide entry
- **`Prefix + Shift+Tab` (`BTab`)**: Instantly toggles to the previous session via `sesh last` (symmetrical with `Prefix + Tab` for `last-window`).
- **Fish Helper `ta`**: Terminal command running `sesh connect` with interactive fuzzy search.

### Interactive Navigation & Popups

- **`Prefix + e`**: Toggles a floating **Yazi** file manager popup at the current pane's path (press `Prefix + e` again to close/dismiss, or `q` to quit). Matches `<leader>e` in Neovim and `Super+e` in desktop compositors.
- **`Prefix + g`**: Toggles a floating Jujutsu TUI (`jjui`) popup taking 85% of the screen (press `Prefix + g` again to close/dismiss, or `q` to quit). Matches `<leader>gg` in Neovim.
- **`Prefix + t`** (or `Prefix + P`): Opens `floax`, a floating terminal scratchpad (matches `<leader>t` in Neovim).
- **`Prefix + /`**: Instantly begins reverse incremental search in scrollback history (`?` in copy mode).
- **`Prefix + o`**: Opens `tmux-window-picker`, a floating interactive FZF popup listing all windows across all sessions with a live preview pane.
- **`Prefix + u`**: Triggers `extrakto` to search and copy URLs, file paths, and hashes from the screen.
- **`Prefix + q`**: Display pane numbers overlay in accent colors for 3 seconds (type number to jump directly to pane).
- **`Prefix + x`**: Kill current pane without confirmation prompt.
- **`Prefix + X`**: Kill current session with confirmation (smoothly jumps to next session).
- **`Prefix + v` / `Prefix + s`**: Split horizontally / vertically preserving current path.
- **`Prefix + _` / `Prefix + \`**: Full-span horizontal split across entire window width / full-span vertical split across entire height.
- **`Prefix + J` / `Prefix + j`**: Interactively select and join a window horizontally / vertically.
- **`Prefix + C-k`**: Hard terminal reset and scrollback history wipe.
- **`Prefix + H / L`** (or `Prefix + Alt + h/j/k/l`): Resize active pane split (repeatable).
- **`Alt + 1..9`**: Directly jump to windows 1 through 9.
- **`Alt + h/j/k/l`**: Move between panes without pressing the prefix key.
- **`Prefix + a`**: Toggles Alt-Passthrough mode, letting `Alt + h/j/k/l` pass through to Neovim (for `mini.move` line shifting).
- **Mouse & Selection**: Double-click selects word (with path/kebab awareness) and copies directly to Wayland clipboard; Triple-click copies line; Drag copies without closing copy-mode.

### Resurrect Store Path Sanitizer (`tmux-resurrect-save`)

On NixOS, running binaries have nix store paths like `/nix/store/abc123...-neovim-0.10.0/bin/.nvim-wrapped`. When `tmux-resurrect` snapshots sessions, these transient store paths get saved. After a system upgrade or garbage collection, restoring the session fails because the old store path no longer exists.

NixConfig includes a custom wrapper script `tmux-resurrect-save`:
1. Strips `/nix/store/.../bin/` prefixes and wrapped binary names (`.nvim-wrapped` -> `nvim`, `.vi-wrapped` -> `vi`, `.bat-wrapped` -> `bat`).
2. Strips temporary Neovim `--cmd lua ...` arguments.
3. Cleans 0-byte corrupt save files.
4. Falls back to the latest valid save (>250 bytes) if a blank bootstrap session was written.
5. Keybindings: `Prefix + S` to save, `Prefix + R` to restore.

---

## Yazi Terminal File Manager

Yazi is configured in `modules/features/apps/development.nix` and set as the default directory opener (`inode/directory` in `default-apps.nix`):

### Custom Opener Rules

```toml
[opener]
edit = [
  { run = '${EDITOR:-nvim} "$@"', block = true, desc = "Editor" }
]
imv = [
  { run = "imv-dir \"$@\"", orphan = true, desc = "Open with imv-dir" }
]

[open]
prepend_rules = [
  { mime = "image/*", use = "imv" },
  { mime = "text/*", use = "edit" }
]
```

### Keybindings & Behaviour

- **`.`**: Toggle hidden files and directories.
- **`T`**: Maximise or restore the preview pane (`plugin toggle-pane --args=max-preview`).
- **`e`**: Open the current directory inside Neovim (`shell 'nvim .' --block`).
- **`y`**: Fish shell abbreviation expanding to `yazi`.
- **SUPER + e**: Compositor keybinding launching `kitty --single-instance -e yazi`.

---

## Pet Snippet Manager

Pet is a command-line snippet manager configured in `modules/packages/pet/default.nix`.

### Fish Interactive Picker (`Ctrl + P`)

Pressing `Ctrl + P` in any interactive Fish session opens `pet search` inside FZF. Selecting a snippet inserts the command directly into the active prompt line for editing or immediate execution.

### Pre-Configured Snippet Library (`~/.config/pet/snippet.toml`)

Includes dozens of tested snippets categorised by tags:
- **NixOS Rebuilds & Flakes**:
  - `nh os switch` - Fast system switch
  - `cd ~/NixConfig && nix flake lock --update-input <input>` - Update single input
  - `cd ~/NixConfig && nix why-depends .#nixosConfigurations.$(hostname).config.system.build.toplevel 'nixpkgs#<pkg>'` - Check dependency chain
  - `sudo nix-collect-garbage -d` - Garbage collect all generations
- **Git & GitHub**:
  - `gh pr create --fill --base <base=main>` - Open PR with auto-filled description
  - `git blame -L <line>,<line> <file>` - Locate line origin
  - `git rebase -i HEAD~<n=5>` - Interactive rebase
- **Tmux**:
  - `tmux attach -t $(tmux list-sessions -F '#{session_name}' | fzf)` - Fuzzy session attach
  - `tmux capture-pane -t <pane=0> -p -S -<lines=500> > <output=pane.txt>` - Capture pane scrollback
- **System & Utility**:
  - `rg -n --hidden --glob '!.git' '<query=TODO|FIXME>' <path=.>` - Search codebase
  - `fd <name> <path=.> | fzf | xargs -r bat --style=plain` - Find file and preview
  - `mmsg get all-clients | jq` - Inspect MangoWC Wayland clients
  - `pet new $(history | tail -n 2 | head -n 1)` - Save last command to Pet

---

## Fish Shell & Starship Prompt

Configured in `modules/features/shell/shell.nix`:

### Cached FZF File Traversal (`__fzf_cache_fd`)

Standard `fzf` file and directory traversal searches the entire directory tree with `fd` on every invocation (`Ctrl + T`, `Alt + C`). In large workspaces like the Linux kernel or complex monorepos, this causes noticeable latency.

NixConfig implements a custom caching function `__fzf_cache_fd`:
- Calculates a SHA-256 hash of the current working directory path.
- Stores the output of `fd --strip-cwd-prefix --hidden --exclude .git` in `/tmp/fzf_fd_cache_$USER/<hash>`.
- Reuses the cached file list for up to **5 minutes** (300 seconds), making subsequent fuzzy file lookups instantaneous.

### Custom Functions & Aliases

- **`nixconf`**: Changes directory to `~/NixConfig` and prints recent Jujutsu commits (`jj log --limit 5`).
- **`nixup`**: Pulls upstream Git commits and runs `nh os switch`.
- **`mkcd <dir>`**: Creates directory and enters it in one command.
- **`y`**: Abbreviation for `yazi`.
- **`nixclean`**: Abbreviation for `sudo nix-collect-garbage --delete-older-than 30d`.
- **`j` / `jl` / `jd` / `js` / `jc` / `jn` / `jp` / `jf`**: Full suite of Jujutsu VCS shortcuts (see [Jujutsu Guide](jujutsu.md)).

### Starship Prompt

- **Transient Prompt**: Reduces previous commands to a minimal `>> ` prompt to preserve terminal vertical space.
- **Character**: Green `╰──>>` on success, red `╰──>>` on error.
- **Context Indicators**:
  - Active Git branch, commit status (ahead, behind, modified, staged, stashed).
  - Runtime indicators for Node.js, Rust, Python when relevant files are detected.
  - Nix shell indicator (`[nix-shell]`).
  - Command execution duration indicator when commands take longer than 2 seconds.
  - Laptop battery indicator with warnings when discharging below 20%.
