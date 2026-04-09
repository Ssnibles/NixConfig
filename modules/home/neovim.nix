# =============================================================================
# Neovim Module (Home Manager)
# =============================================================================
# Installs Neovim with curated plugins, LSP servers, and formatters.
# Configuration is sourced from the nvim/ directory (Lua-based).
#
# Architecture:
#   • Nix: Plugin/tool installation (this file)
#   • Lua: Runtime configuration (nvim/init.lua + nvim/lua/*)
#   • Zero plugin manager overhead (plugins provided via runtimepath by Nix)
#
# Plugin Philosophy:
#   • Minimal: Only essential plugins (no bloat)
#   • Native-first: Prefer built-in Neovim features when possible
#   • Performance: Lazy-loading where beneficial, async operations
#   • Modern: Uses Neovim 0.10+ APIs (diagnostics, LSP, treesitter)
#
# LSP Servers Included:
#   • Nix (nixd), Lua (lua-language-server)
#   • Python (pyright), TypeScript/JavaScript (vtsls)
#   • Kotlin (kotlin-language-server), Java (jdt-language-server)
#   • C# (roslyn-ls), Markdown (marksman)
#
# Formatters Included:
#   • Nix (nixfmt-rfc-style), Lua (stylua)
#   • Python (black + isort), JavaScript/TypeScript (prettier)
#   • Shell (shfmt), Kotlin (ktlint), Java (google-java-format)
#   • C# (csharpier)
# =============================================================================
{ pkgs, ... }:
let
  # ── Custom Plugin: tiny-code-action ────────────────────────────────────────
  # Lightweight code action UI (alternative to heavier Telescope code actions)
  # Source: https://github.com/rachartier/tiny-code-action.nvim
  tiny-code-action = pkgs.vimUtils.buildVimPlugin {
    pname = "tiny-code-action";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "rachartier";
      repo = "tiny-code-action.nvim";
      rev = "main";
      sha256 = "sha256-oZalIk5m+XtwvPWjI+Ds/IoM4nM0w9BEoI5YYI1B/PI=";
    };
    doCheck = false;
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Set as system default editor ($EDITOR, $VISUAL)
    viAlias = true; # Create 'vi' command alias
    vimAlias = true; # Create 'vim' command alias

    # ═══════════════════════════════════════════════════════════════════════
    # LSP SERVERS & FORMATTERS
    # ═══════════════════════════════════════════════════════════════════════
    # Tools installed system-wide, available on PATH for Neovim LSP config
    extraPackages = with pkgs; [
      # ── LSP Servers ──────────────────────────────────────────────────────
      nixd # Nix language server (better than nil/rnix)
      lua-language-server # Lua LSP (Neovim config development)
      pyright # Python LSP (type checking, completion)
      vtsls # TypeScript/JavaScript LSP (fast, modern)
      kotlin-language-server # Kotlin LSP
      jdt-language-server # Java LSP (Eclipse JDT.LS)
      marksman # Markdown LSP (navigation, links)
      roslyn-ls # C# LSP (Roslyn-based)

      # ── Formatters & Tools ───────────────────────────────────────────────
      nixfmt-rfc-style # Nix formatter (RFC 166 style)
      stylua # Lua formatter (opinionated)
      black # Python formatter (PEP 8)
      isort # Python import sorter
      prettier # JavaScript/TypeScript/CSS/HTML formatter
      shfmt # Shell formatter
      ktlint # Kotlin formatter
      google-java-format # Java formatter
      csharpier # C# formatter
      dotnet-sdk_10 # .NET SDK (required for Roslyn LSP)

      # ── CLI Tools (used by plugins) ──────────────────────────────────────
      tree-sitter # Syntax parser (used by nvim-treesitter)
      ripgrep # Fast grep (fzf-lua, telescope, live grep)
      fd # Fast find (fzf-lua file search)
    ];

    # ═══════════════════════════════════════════════════════════════════════
    # PLUGINS
    # ═══════════════════════════════════════════════════════════════════════
    # Plugins are provided on runtimepath by Nix (no plugin manager needed)
    # Configuration lives in nvim/lua/plugins/*.lua
    plugins = with pkgs.vimPlugins; [
      # ── Custom Plugins ───────────────────────────────────────────────────
      tiny-code-action # Lightweight code action UI

      # ── Syntax & Parsing ─────────────────────────────────────────────────
      (nvim-treesitter.withPlugins (
        p: with p; [
          # Core languages
          lua
          vim
          nix
          bash
          fish

          # JVM languages
          kotlin
          java

          # Web development
          javascript
          typescript
          tsx
          html
          css
          json
          yaml

          # Other
          python
          markdown
          c_sharp
        ]
      ))
      nvim-treesitter-context # Show code context at top of window
      nvim-treesitter-textobjects # Text objects based on tree-sitter

      # ── LSP & Completion ─────────────────────────────────────────────────
      nvim-lspconfig # LSP client configurations
      blink-cmp # Fast completion engine (Rust-based)
      luasnip # Snippet engine
      friendly-snippets # Community snippet collection
      copilot-lua # GitHub Copilot integration
      fidget-nvim # LSP progress notifications
      roslyn-nvim # C# LSP integration (Roslyn-specific)
      tiny-inline-diagnostic-nvim # Inline diagnostic messages

      # ── Fuzzy Finding & Navigation ───────────────────────────────────────
      fzf-lua # Fast fuzzy finder (Lua-based)
      fyler-nvim # Tree file manager
      leap-nvim # Fast motion (replaces EasyMotion)
      smart-splits-nvim # Smart split navigation and resizing

      # ── UI & Appearance ──────────────────────────────────────────────────
      lualine-nvim # Statusline
      statuscol-nvim # Custom status column (signs, line numbers)
      neoscroll-nvim # Smooth scrolling
      vague-nvim # Colorscheme (Vague theme)
      nui-nvim # UI dependency for noice.nvim
      noice-nvim # Better UI for messages, cmdline, popups

      # ── Git Integration ──────────────────────────────────────────────────
      gitsigns-nvim # Git signs in gutter (add/change/delete)
      neogit # Magit-like Git interface

      # ── Code Editing ─────────────────────────────────────────────────────
      nvim-autopairs # Auto-close brackets, quotes
      conform-nvim # Formatter runner (async formatting)
      grug-far-nvim # Search and replace across project

      # ── Utilities ────────────────────────────────────────────────────────
      mini-nvim # Mini.nvim suite (various small utilities)
      plenary-nvim # Lua utility library (dependency for many plugins)
      vim-tmux-navigator # Seamless tmux/vim navigation
      markview-nvim # Markdown preview in buffer
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # LUA CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  # Source Lua config from nvim/ directory in the repository
  # Structure: init.lua (entry) → lua/options.lua, lua/keymaps.lua, lua/plugins/*
  xdg.configFile."nvim" = {
    source = ../../nvim;
    recursive = true;
  };
}
