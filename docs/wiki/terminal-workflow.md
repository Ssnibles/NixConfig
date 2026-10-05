# Terminal Workflow: Kitty, Tmux, Yazi, Navi & Shell Environment

This guide documents the terminal environment in NixConfig, covering the Kitty terminal emulator, Tmux multiplexer, Yazi file manager, Navi cheatsheet picker, and the Fish shell with Starship prompt.

---

## Overview

The terminal environment is engineered for low latency, memory efficiency, and fast navigation:

| Layer | Component | Key Highlights | Configuration File |
| :--- | :--- | :--- | :--- |
| **Terminal** | **Kitty** | Single-instance server mode, shared GPU sprite cache, Maple Mono font | `modules/features/apps/kitty.nix` |
| **Alternative** | **Foot** | Lightweight Wayland native terminal | `modules/packages/foot/default.nix` |
| **Multiplexer** | **Tmux** | Backtick prefix, Sesh session picker, resurrect path sanitiser, floating popups | `modules/features/shell/tmux.nix` |
| **File Manager** | **Yazi** | Async Rust file manager, image previews, Neovim directory opening | `modules/features/apps/development.nix` |
| **Cheatsheets** | **Navi** | Fuzzy command cheatsheet insertion bound to `Ctrl+P` | `modules/packages/navi/default.nix` |
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
- **Palette Tokens**: All 16 ANSI colours and window backgrounds (`bg`, `fg`, `accent`, `border`, `selection`) are generated dynamically from the active theme palette (`config.theme.colours`).

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
- **`Prefix + q`**: Display pane numbers overlay in accent colours for 3 seconds (type number to jump directly to pane).
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

### Resurrect Store Path Sanitiser (`tmux-resurrect-save`)

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

## Navi Cheatsheet Manager

Navi is a command-line cheatsheet picker (an actively maintained Rust alternative to the now-idle `pet`) configured in `modules/packages/navi/default.nix`.

### Fish Interactive Picker (`Ctrl + P`)

Pressing `Ctrl + P` in any interactive Fish session opens navi's FZF picker. Selecting a cheat inserts the command directly into the active prompt line for editing or immediate execution. Navi then prompts for each `<variable>`; variables that had a default in the old pet library are pre-filled through a `$ name: ...` suggestion line.

The picker includes a live preview pane (navi's built-in `navi preview`) showing the cheat's comment, tags, and full command template. `finder.overrides` in `config.yaml` widens it to `right:55%:wrap` and binds `Ctrl-/` to toggle it.

### Tmux Popup (`Prefix + Ctrl-g`)

`Prefix + Ctrl-g` (bound in `modules/features/shell/tmux.nix`) opens the same picker in a floating `tmux display-popup` and pastes the chosen cheat — unexecuted — into the pane that opened the popup for in-place editing. Because it shells out to navi rather than the shell widget, it works from any pane, including remote SSH sessions and from inside editors.

### Declarative Cheatsheet Library (`~/.config/navi/`)

The library is **declared in Nix**, not edited with an editor. `modules/packages/navi/default.nix` defines every cheat as typed Nix data and renders it to navi `.cheat` files under `~/.config/navi/cheats/` (`core`, `nix`, `git`, `jj`, `tmux`, `files`, `system`, `mango`, `on-demand`); `~/.config/navi/config.yaml` points navi at that directory. The generated files are read-only store symlinks, so add or change cheats in the Nix module and rebuild.

Placeholders use navi's `<name>` syntax; a default is supplied by a following `$ name: echo 'default'` suggestion line. Defaults that were themselves shell commands, such as `$(git branch --show-current)`, become `$ name: git branch --show-current` so navi evaluates them for suggestions.

Representative cheats by category:
- **Nix / NixOS**:
  - `nh os switch` - Fast system switch
  - `nh clean all --keep <n>` (default `10`) - Garbage collect, keeping the last N generations
  - `cd ~/NixConfig && nix flake update <input>` (default `nixpkgs-unstable`) - Update a single input
  - `cd ~/NixConfig && nix flake check` - Validate the flake
  - `cd ~/NixConfig && nix why-depends .#nixosConfigurations.$(hostname).config.system.build.toplevel 'nixpkgs#<pkg>'` - Check dependency chain
  - `nix-locate --whole-name bin/<name>` (default `neovim`) - Find which package provides a binary (nix-index)
- **Git & GitHub**:
  - `gh pr create --fill --base <base>` (default `main`) - Open PR with auto-filled description
  - `gh pr checkout <number>` (default `1`) - Check out a pull request
  - `git blame -L <start>,<end> <file>` - Locate line origin
  - `git commit --fixup=<target> && git rebase -i --autosquash <base>` - Fixup + autosquash
- **Jujutsu (`jj`)**:
  - `jj new 'trunk()'` - Start work on top of trunk
  - `jj describe -m '<message>'` - Describe the current change
  - `jj undo` - Undo the last operation
- **Tmux**:
  - `tmux attach -t $(tmux list-sessions -F '#{session_name}' | fzf)` - Fuzzy session attach
  - `sesh picker` - Sesh session picker
  - `tmux capture-pane -t <pane> -p -S -<lines> > <output>` - Capture pane scrollback
- **Files & System**:
  - `rg -n --hidden --glob '!.git' '<query>' <path>` - Search codebase
  - `rg --files | fzf | xargs -r nvim` - Fuzzy-open a file in Neovim
  - `yazi <dir>` - Open Yazi in a directory
  - `zip -r <output> <target>` / `unzip <archive> -d <dest>` - Create and extract zip archives (plus `unzip -l` to list and single-member extraction)
  - `python3 -m http.server <port> --bind 127.0.0.1 -d <dir>` - Local file server
  - `mmsg get all-clients | jq` - Inspect MangoWC Wayland clients
- **On-demand tools**:
  - `nix shell nixpkgs#<package> -c <command> <args>` - Grab a package and run it with arguments; `<command>` defaults to the package name (e.g. `nix shell nixpkgs#dust -c dust ./`)
  - `nix run nixpkgs#<package> -- <args>` - Run a package's default command without installing it

---

## Fish Shell & Starship Prompt

Configured in `modules/features/shell/shell.nix`:

### Cached FZF File Traversal (`__fzf_cache_fd`)

Standard `fzf` file and directory traversal searches the entire directory tree with `fd` on every invocation (`Ctrl + T`, `Alt + C`). In large workspaces like the Linux kernel or complex monorepos, this causes noticeable latency.

NixConfig implements a custom caching function `__fzf_cache_fd`:
- Calculates a SHA-256 hash of the current working directory path.
- Stores the output of `fd --strip-cwd-prefix --hidden --exclude .git` in `/tmp/fzf_fd_cache_$USER/<hash>`.
- Reuses the cached file list for up to **5 minutes** (300 seconds), making subsequent fuzzy file lookups instantaneous.

### Zoxide Directory Picker (`Alt + Z`)

`zoxide` provides two fish commands via `programs.zoxide.enableFishIntegration`:

- **`z <query>`**: Direct frecency jump (no UI).
- **`zi`**: Interactive picker — `zoxide query --interactive` pipes zoxide's ranked directory history into `fzf`, then `cd`s to the selection. Because it drives `fzf` directly, it inherits the themed `FZF_DEFAULT_OPTS` (rounded border, `ls -la` preview for directories). Pass a query to pre-filter, e.g. `zi nix`.
- **`Alt + Z`**: Keybinding that runs `zi` from the command line without typing it (bound in both default and insert modes), mirroring the existing `Ctrl + P` cheatsheet picker.

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
