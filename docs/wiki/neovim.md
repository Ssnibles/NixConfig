# Declarative Neovim

Neovim is built from the nightly overlay and configured by a Lua tree that is
symlinked into the home directory. Nix owns packages; Lua owns behaviour.

## Ownership

| Layer | Owner | Rebuild needed |
| :--- | :--- | :--- |
| Package, plugins, treesitter grammars, LSPs, formatters, linters, debug adapters | `modules/features/apps/neovim.nix` | yes |
| Options, keymaps, autocommands, LSP settings, theme | `modules/features/nvim-src/` | no |

`nvim-src/` is linked to `~/.config/nvim` for the user and root, so editing Lua
is live. There is no runtime plugin manager: everything is on the packpath at
startup.

## Wrapper

`neovim.nix` wraps the nightly package with `pkgs.wrapNeovimUnstable`:

- `wrapRc = false`, so `VIMINIT` is unset and `~/.config/nvim/init.lua` loads
  like any normal install.
- `plugins` are injected through the packpath. They are the same list that was
  on the runtimepath before.
- `wrapperArgs` puts every tool on `PATH` (ahead of the system) and exports
  `NVIM_JAVA_BUNDLES` for nvim-jdtls.
- `viAlias` and `vimAlias` create `vi` and `vim`, and `EDITOR` is set to `nvim`.

## Layout

All line counts include comments. Files marked "data" are carried over.

```
modules/features/nvim-src/                4855 lines
├── init.lua                               29   leader, loader, ui2, requires
├── lsp/                                   one file per server, 17 total
│   ├── clangd.lua                         43   Nix C flags via before_init
│   ├── nixd.lua                           83   flake root and host detection
│   └── <server>.lua                            declarative tables
├── snippets/                              data: java 18, nix 91, typst 979
└── lua/
    ├── options.lua                        84   all vim.opt and Neovide globals
    ├── filetypes.lua                      5
    ├── commands.lua                       3    :Mes
    ├── autocmds.lua                       159  one augroup per feature
    ├── util.lua                           85   toggles, helper filetypes, capabilities, C flags
    ├── external.lua                       48   optional binaries, the only place they are named
    ├── terminal.lua                       86   reused shell buffer
    ├── diagnostics.lua                    76   vim.diagnostic, inline text, fidget
    ├── vcs.lua                            105  gitsigns, grug-far, jjui
    ├── theme/
    │   ├── init.lua                       82   palette, mini.base16, fold text
    │   └── highlights.lua                 237  data
    ├── ui/
    │   ├── init.lua                       12
    │   ├── statusline/
    │   │   ├── init.lua                   64   assembly and width budget
    │   │   ├── mode.lua                   82   mode, selection, macro
    │   │   ├── context.lua                119  search, git, diagnostics
    │   │   ├── info.lua                   54   dap, format, filetype, position
    │   │   ├── filename.lua               101  headers and path truncation
    │   │   ├── icons.lua                  27
    │   │   └── util.lua                   10
    │   ├── cmdline.lua                    28   ui2 command bar
    │   ├── flash.lua                      34
    │   ├── splits.lua                     7
    │   ├── dial.lua                       19
    │   └── render.lua                     19   markview, indent guides, autotag
    ├── edit/
    │   ├── init.lua                       6
    │   ├── treesitter.lua                 24   textobjects and context
    │   ├── enter.lua                      115  list continuation
    │   ├── mini.lua                       96   mini modules and mini.clue
    │   └── replace.lua                    35   buffer find and replace
    ├── completion/
    │   ├── init.lua                       5
    │   ├── snippets.lua                   24
    │   ├── blink.lua                      122
    │   ├── sources.lua                    58
    │   └── copilot.lua                    53
    ├── lsp/
    │   ├── init.lua                       50   registration and :LspHealth
    │   ├── attach.lua                     86   attach maps, inlay hints, codelens
    │   └── ui.lua                         17   aerial and goto-preview
    ├── tools/
    │   ├── init.lua                       4
    │   ├── format.lua                     76   conform and autoformat toggles
    │   └── lint.lua                       84   nvim-lint
    ├── keymaps/                           global maps only, grouped by domain
    │   ├── init.lua                       9
    │   ├── groups.lua                     18   leader labels for mini.clue
    │   ├── editor.lua                     67
    │   ├── motion.lua                     56
    │   ├── windows.lua                    70
    │   ├── code.lua                       76
    │   ├── find.lua                       39
    │   ├── debug.lua                      48
    │   └── lang.lua                       24
    ├── nav/
    │   ├── init.lua                       5
    │   ├── picker.lua                     85   fzf-lua and vim.ui.select
    │   ├── files.lua                      73   oil and image paste
    │   └── rename.lua                     70   :SmartRename
    ├── debugger/
    │   ├── init.lua                       12   dap-view
    │   └── adapters.lua                   129  Python, Go, LLDB, JS
    └── lang/
        ├── init.lua                       6
        ├── rust.lua                       38
        ├── c.lua                          57
        ├── typst.lua                      46
        └── java.lua                       83
```

`init.lua` sets the leader, enables the Lua loader and ui2, then requires the
modules in this order: options, filetypes, commands, theme, ui, edit,
completion, lsp, diagnostics, tools, nav, vcs, debugger, lang, terminal,
autocmds, keymaps. Modules require their own dependencies where they are used,
so the order is not load-bearing.

## Live edit property

The Lua tree is symlinked, so options, keymaps, autocommands, theme, LSP server
tables and snippets change on the next start with no rebuild. Adding or removing
a plugin or tool needs a rebuild because it is a Nix change.

## Language servers

Server definitions are plain tables in `lsp/<server>.lua`, which `vim.lsp.config`
resolves by name. The managed server list is derived from those files, so adding
a server means adding one file and nothing else. A server is enabled only when
its executable exists, so an optional server that is not installed stays quiet.
`:LspHealth` lists every managed server and whether it was found, plus the
clients attached to the current buffer.

`clangd.lua` injects the include flags from the current `nix develop` shell in
`before_init`. `nixd.lua` detects the flake root and host at runtime.

Specialised wrappers still live in Nix: `qmlls` gets the QtQuick and Quickshell
import paths, and `zls` gets the Wayland, wlroots and pixman header paths.

## Keymaps

All global maps live under `lua/keymaps/`, one file per domain, and every map
has a `desc`. Buffer-local maps live with the feature that owns the buffer:
LSP attach, gitsigns, aerial, clangd, java and typst. mini.clue (which-key) is
enabled: leader groups are defined in `keymaps/groups.lua` and used by the
menu, so the menu and the maps cannot drift apart.

470 explicit left-hand sides, matching the pre-rebuild dump.

## Statusline

`ui/statusline/` renders a zline-style statusline with the native 'statusline'
expression:

- Left: mode badge, visual selection size, macro register, search count, git
  branch with coloured diff counters, and error and warning counts.
- Right: DAP status, format and encoding warnings, filetype and position.
- The filename segment handles quickfix, help, terminal, oil, man and grug-far
  headers, and truncates long paths from the left so the tail stays visible.
- Inactive windows get a dimmed path and their own line count.
- File and filetype icons come from mini.icons. Spell and LSP client segments
  are off, matching the previous zline configuration.
- `showcmd` is off, so pending keys such as operators and counts never appear
  in the statusline. mini.clue still shows the key menu after a prefix.

`ui/statusline/init.lua` measures the left and right segments, gives the
filename the remaining width with a margin, and leaves the command line alone.

## Command line

`cmdheight=0` plus ui2 gives a full-width command bar above the statusline.
`ui/cmdline.lua` styles the `cmd` window with `StlCmdText`, clears the search
highlights the way ui2 does, and raises `cmdwinheight` to 15 for `q:`.

The typed command text stays in that bar, not in the statusline. While a `/` or
`?` pattern is typed, the statusline search segment shows the live count and
`FWD` or `BWD`, or `NO MATCH`. The typed pattern is counted without replacing
the last committed search pattern.

## Toggles

| Key | Feature | State |
| :--- | :--- | :--- |
| `<leader>tw` | wrap | `wrap` |
| `<leader>ts` | spell | `spell` |
| `<leader>tn` | relative numbers | `relativenumber` plus `vim.w.relativenumber_enabled` for insert mode |
| `<leader>td` | diagnostics | `vim.diagnostic.enable()` |
| `<leader>tD` | inline diagnostics | tiny-inline-diagnostic |
| `<leader>ti` | inlay hints | `vim.lsp.inlay_hint` |
| `<leader>tc` | cursor word | `vim.b.minicursorword_disable` |
| `<leader>tF` | autoformat (global) | module state in `tools/format.lua` |
| `<leader>tA` | autoformat (filetype) | module state in `tools/format.lua` |
| `<leader>tp` | Typst preview | buffer-local, Typst only |

No `vim.g.disable_*` or `vim.g.*_enabled` flags are read across files.

## Commands

`:Mes`, `:LspHealth`, `:GenerateCompileFlags`, `:Format` (`:Format!` saves),
`:OilPasteImage`, `:SmartRename`. `:lsp restart` is built in.

## Language support

| Language | Server | Formatter | Linter |
| :--- | :--- | :--- | :--- |
| Rust | rust-analyzer (rustaceanvim) | rustfmt | clippy |
| Zig | zls (Wayland wrapper) | zig fmt | zls |
| C / C++ | clangd (clangd_extensions) | clang-format | cppcheck |
| Nix | nixd | nixfmt | statix, deadnix |
| Python | pyright | isort, black | pyright |
| JavaScript / TypeScript | vtsls, eslint, emmet_ls | prettierd | eslint |
| Lua | lua-language-server | stylua | lua-language-server |
| Typst | tinymist, ltex_plus | typstyle | tinymist |
| QML / QtQuick | qmlls (QtQuick wrapper) | none | qmlls |
| Java | jdtls (nvim-jdtls) | google-java-format | jdtls |
| Kotlin | kotlin-language-server | ktlint | ktlint |
| Go | gopls | gopls | gopls |
| Markdown | marksman, ltex_plus | prettierd | ltex_plus |

## Migration from the NVF build

What changed:

- NVF is gone. `NVIM_APPNAME=nvf`, the `~/.config/nvf` links and the
  `dofile(stdpath("config"))` escape hatch are removed. `~/.config/nvim` is now
  the real config path.
- zline, sshinator and startinator are no longer loaded from `$HOME`. The
  statusline is built in, and the `vim._core.ui2.cmd` handler poke is gone.
- The five state globals are gone: `relativenumber_enabled`,
  `disable_autoformat`, `disable_autoformat_ft`, `minicursorword_disable` and
  `java_debug_bundles`. Autoformat state lives in `tools/format.lua`, the Java
  bundles arrive in `NVIM_JAVA_BUNDLES`.
- `smart_enter.lua` is gone. Comment continuation is `formatoptions` `r`; list
  continuation lives in `edit/enter.lua`.
- `:Mes`, `:Format`, `:LspHealth`, `:GenerateCompileFlags`, `:OilPasteImage` and
  `:SmartRename`, and every keybinding, still work.

Needs a rebuild:

- The package, plugin list and PATH are Nix changes. Run the normal rebuild
  once.

State directories moved:

- Because `NVIM_APPNAME` is no longer `nvf`, `stdpath("data")`,
  `stdpath("state")` and `stdpath("cache")` now point at `nvim` instead of
  `nvf`. Oldfiles, shada, undo history and LSP caches start empty unless copied:

  ```sh
  cp -a ~/.local/share/nvf/. ~/.local/share/nvim/
  cp -a ~/.local/state/nvf/. ~/.local/state/nvim/
  cp -a ~/.cache/nvf/. ~/.cache/nvim/
  ```

- `~/.config/nvf` is no longer linked; the old link can be deleted.
