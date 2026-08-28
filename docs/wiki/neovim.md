# Declarative Neovim & Lua Plugin Configuration

This guide details the Neovim editor setup in `NixConfig`. Neovim is built declaratively using [nvf](https://github.com/NotAShelf/nvf) and extended with custom Lua plugins under `modules/features/nvim-src/`.

---

## 📂 Codebase Layout

```
modules/features/apps/neovim.nix        # Declarative nvf Neovim package definition
modules/features/nvim-src/              # Custom Lua plugins & editor settings
├── init.lua                            # Top-level Lua initialization
├── .luacheckrc                         # Static linter configuration
└── lua/
    ├── config/                         # Keymaps, options, autocommands
    └── plugins/                        # Plugin modules
        ├── c.lua                       # Clangd extensions & GenerateCompileFlags command
        ├── fidget.lua                  # LSP progress notifications
        ├── typst-snippets.lua          # Markup & document snippets
        └── ...
```

---

## ⚡ Key Features

### 1. C / C++ LSP & `GenerateCompileFlags` (`plugins/c.lua`)
`plugins/c.lua` provides a custom command **`:GenerateCompileFlags`** that queries your active Nix development shell environment (`CPATH`, `NIX_CFLAGS_COMPILE`, `pkg-config`) and writes a project-local `compile_flags.txt`:

```vim
:GenerateCompileFlags
```
This enables full LSP completion, macro expansion, and include paths for C libraries (Raylib, Wayland, SDL2) and microcontroller code (ESP32 Arduino).

### 2. Clangd Inlay Hints & AST Inspection
`clangd_extensions` is configured with inline parameter hints (`<- param`), return type hints, AST role icons, and memory usage inspection windows.

### 3. Integrated LSP Diagnostics & Status
`fidget.nvim` provides non-intrusive bottom-right status UI for background LSP indexing, formatting, and analysis tasks.
