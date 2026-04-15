# Neovim stack

## Where config lives

- Nix module: `modules/home/neovim.nix`
- Runtime config: `nvim/init.lua`, `nvim/lua/*`

Nix installs plugins/tools directly, so no plugin manager bootstrap is required.

## LSP/formatter toolchain

Installed via `programs.neovim.extraPackages`:

- LSPs: `nixd`, `lua-language-server`, `pyright`, `vtsls`, `kotlin-language-server`, `jdt-language-server`, `marksman`, `roslyn-ls`
- Formatters/tools: `nixfmt-rfc-style`, `stylua`, `black`, `isort`, `prettier`, `shfmt`, `ktlint`, `google-java-format`, `csharpier`
- Debug adapters/tools: `debugpy`, `netcoredbg`, `delve`, `lldb` (`lldb-dap`), `vscode-js-debug`

Default DAP configs are provided for:

- Python, C#, Go
- JavaScript/TypeScript (+ React variants)
- Java/Kotlin (JDWP attach)
- Rust/C/C++ (LLDB)

## Plugin set

The module includes:

- treesitter + context/textobjects
- LSP/completion (`nvim-lspconfig`, `blink-cmp`, snippets, Copilot)
- diagnostics/debug UX (`trouble`, DAP UI stack, fidget, tiny diagnostics)
- fuzzy/navigation (`fzf-lua`, oil.nvim, flash, smart-splits)
- UI (`lualine`, `noice`, `statuscol`, `twilight`, `snacks`, etc.)
- git (`gitsigns`, `neogit`)
- editing (`conform`, `autopairs`, `dial`, `multicursors`)
- custom plugins:
  - `tiny-code-action.nvim`
  - local `switcheroo` from flake input `switcheroo-src`

## Keymaps

Core editor keymaps are in `nvim/lua/keymaps.lua`.  
Plugin-specific mappings are defined in each plugin config file under `nvim/lua/plugins/`.
