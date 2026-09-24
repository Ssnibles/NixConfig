# Declarative Neovim & Lua Plugin Architecture

This guide details the Neovim editor environment in NixConfig. Neovim is constructed declaratively using the [nvf](https://github.com/NotAShelf/nvf) framework and extended through a modular Lua configuration tree in `modules/features/nvim-src/`.

---

## Architecture Overview

The Neovim installation decouples package management and system binary paths from editing logic:

```
NixOS Module (modules/features/apps/neovim.nix)
├── Declarative package definition via nvf
├── LSPs, formatters, linters, and DAPs pinned via Nixpkgs
├── Tree-Sitter grammars compiled ahead of time
└── System activation script:
    symlinks modules/features/nvim-src/ -> ~/.config/nvim and ~/.config/nvf
```

Because `nvim-src/` is symlinked directly from your Git workspace, you can edit Lua plugins, keymaps, and autocommands with instant reloading without requiring a full `nixos-rebuild`.

---

## Codebase Layout (`modules/features/nvim-src/`)

```
modules/features/nvim-src/
├── init.lua                            # Top-level Lua entry point
└── lua/
    ├── autocmds.lua                    # Auto-commands (highlight on yank, cursor recall)
    ├── keymaps.lua                     # Global keybindings (<leader> = Space)
    ├── smart_enter.lua                 # Context-aware Enter key handling
    ├── theme.lua                       # Dynamic color overrides matching system palette
    │
    ├── lsp/
    │   ├── init.lua                    # LSP client configuration & diagnostic handlers
    │   └── servers.lua                 # Server definitions (nixd, pyright, marksman, tinymist, etc.)
    │
    ├── plugins/
    │   ├── completion.lua              # Blink.cmp, Luasnip, Copilot, friendly-snippets
    │   ├── dap.lua                     # nvim-dap, DAP UI, Python & LLDB debug adapters
    │   ├── diagnostics.lua             # tiny-inline-diagnostic-nvim, fidget status notifications
    │   ├── editor.lua                  # Oil, Gitsigns, Grug-far, Flash, smart-splits, jjui popup
    │   ├── format.lua                  # Conform.nvim formatting definitions
    │   ├── fzf.lua                     # FZF-Lua fuzzy finders
    │   ├── lang.lua                    # Rustaceanvim, Clangd extensions, GenerateCompileFlags
    │   ├── lint.lua                    # nvim-lint static linters
    │   ├── mini.lua                    # Mini.nvim (pairs, surround, ai, move, comment)
    │   ├── terminal.lua                # Embedded floating terminal buffers
    │   └── treesitter.lua              # Treesitter context & text-objects
    │
    └── snippets/                       # Filetype snippets (Nix, Typst, Java)
```

---

## Specialized Language Server Wrappers

Standard language servers often struggle with Nix store paths, Wayland system headers, or custom Qt modules. NixConfig wraps these language servers in `modules/features/apps/neovim.nix`:

### 1. `qmlls` (QtQuick & Quickshell Type Checking)
To enable real-time autocompletion and diagnostic validation inside Quickshell QML files, `qmlls` is wrapped with include paths pointing to Qt 6 declarative modules and the Quickshell QML import library:
```bash
qmlls -I /nix/store/...-qtdeclarative/lib/qt-6/qml \
      -I /nix/store/...-quickshell/lib/qt-6/qml "$@"
```

### 2. `zls` (Zig Wayland Compositor Development)
When developing Wayland compositors (like MangoWC) or C/Zig system utilities, `zls` is wrapped to automatically export `CPATH` and `PKG_CONFIG_PATH` referencing Wayland, wlroots, libxkbcommon, libinput, libdrm, and pixman header directories.

---

## Key Features & Custom Commands

### 1. C/C++ LSP & `:GenerateCompileFlags`
Defined in `lua/plugins/lang.lua`. When opening a C project without a CMake compilation database (e.g. Raylib, Wayland, or Arduino code), run:
```vim
:GenerateCompileFlags
```
This inspects the active development shell environment (`CPATH`, `NIX_CFLAGS_COMPILE`, and `pkg-config`), constructs a project-local `compile_flags.txt`, and reloads Clangd.

### 2. Oil File Manager & Clipboard Image Pasting
- **`<leader>e`**: Opens Oil in a floating modal centered on the screen.
- **`<leader>p`** or **`:OilPasteImage`**: Automatically reads image data from the Wayland clipboard (`wl-paste -t image/png`) and prompts for a filename to save the image directly into the active Oil directory.

### 3. Jujutsu VCS Integration (`<leader>gg`)
Pressing **`<leader>gg`** spawns an embedded terminal floating window (85% width and height) running **`jjui`** in the repository root. Exiting `jjui` cleanly closes the floating window and refreshes modified buffers.

### 4. Non-Colliding Git Blame & Inline Diagnostics
- Gitsigns displays inline Git blame at the end of the line (`current_line_blame`).
- To prevent blame text from overlapping `tiny-inline-diagnostic-nvim` errors, an autocommand dynamically hides the Git blame on lines with active compiler warnings or errors.

### 5. Blink.cmp Completion Engine
- Fast completion engine with fuzzy path and symbol search.
- Pre-configured sources: LSP symbols, path completion, snippets, Copilot completions, and dictionary spell checking.

### 6. Fast Find & Replace
- **`<leader>fr`**: Triggers a buffer-local find-and-replace prompt with the current word under cursor pre-filled.
- **`<leader>sg`**: Opens **Grug-far** for project-wide interactive search and replace with live diffing.

### 7. Rust Development (`Rustaceanvim`)
- **`<leader>rr`**: Runnables picker
- **`<leader>rt`**: Testables picker (runs tests in background)
- **`<leader>rm`**: Expand macro at cursor
- **`<leader>ro`**: Open docs for symbol
- **`<leader>rs`**: Restart Rust-Analyzer server

---

## Language Support & Formatters

Format-on-save is managed by `conform.nvim` across all major languages:

| Language | Language Server (LSP) | Formatter | Linter / Diagnostics |
| :--- | :--- | :--- | :--- |
| **Rust** | `rust-analyzer` (via rustaceanvim) | `rustfmt` | `clippy` |
| **Zig** | `zls` (Wayland header wrapped) | `zig fmt` | compiler diagnostics |
| **C / C++** | `clangd` (with clangd_extensions) | `clang-format` | `cppcheck`, `cpplint` |
| **Nix** | `nixd` | `nixfmt` | `statix`, `deadnix` |
| **Python** | `pyright` | `black`, `isort` | `ruff` / `flake8` |
| **JavaScript / TypeScript** | `vtsls` / `eslint` | `prettierd` | `eslint` |
| **Lua** | `lua-language-server` | `stylua` | `luacheck` |
| **Typst** | `tinymist` | `typstyle` | `tinymist` |
| **QML / QtQuick** | `qmlls` (QtQuick wrapped) | manual | `qmlls` |
| **Java / Kotlin** | `jdtls` / `kotlin-ls` | `google-java-format`, `ktlint` | compiler diagnostics |
