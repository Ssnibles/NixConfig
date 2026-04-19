# Neovim stack

## Where config lives

- Nix module: `modules/home/neovim.nix`
- Runtime config: `nvim/init.lua`, `nvim/lua/*`

The stack uses `programs.nvf` as the Neovim configuration framework.
Simple editor defaults and plugin/runtime wiring are declarative in Nix, while
advanced behavior (autocmds, plugin-specific setup, DAP, etc.) stays in Lua.

Neovim is pinned to nightly via the `neovim-nightly-overlay` input, but the
config only overrides `pkgs.neovim` / `pkgs.neovim-unwrapped` instead of using
the overlay's full plugin set. This keeps plugin derivations on the normal
nixpkgs path (better cache hit rate and fewer local plugin builds/tests).

## LSP/formatter toolchain

Installed via `programs.nvf.settings.vim.extraPackages`:

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

`grug-far.nvim` is kept with `doCheck = false` here to avoid flaky upstream
plugin tests during nightly Neovim rebuilds.

## Keymaps

Core editor keymaps are in `nvim/lua/keymaps.lua`.  
Plugin-specific mappings are defined in each plugin config file under `nvim/lua/plugins/`.
