# =============================================================================
# Neovim Module (Home Manager + nvf)
# =============================================================================
# Architecture:
#   • nvf (Nix): Wrapper, simple editor defaults, plugin/runtime provisioning
#   • Lua: Advanced custom behavior (autocmds, plugin-specific logic, DAP, etc.)
# =============================================================================
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  themeName = import ../../lib/stylix/current-theme.nix;
  themes = import ../../lib/stylix/themes.nix;
  selectedTheme =
    if builtins.hasAttr themeName themes then
      themes.${themeName}
    else
      {
        scheme = "catppuccin-mocha.yaml";
        polarity = "dark";
      };

  c =
    (import ../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; }).withHash;
  s = config.lib.stylix.colors.withHashtag;

  tiny-code-action = pkgs.vimUtils.buildVimPlugin {
    pname = "tiny-code-action";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "rachartier";
      repo = "tiny-code-action.nvim";
      rev = "main";
      sha256 = "sha256-DdITbY62jlEhd12TxocJYe/9vZAn7ziEzOMGTp4hb38=";
    };
    doCheck = false;
  };
in
{
  programs.nvf = {
    enable = true;
    defaultEditor = true;

    settings.vim = {
      # Simple baseline behavior managed declaratively via nvf.
      viAlias = true;
      vimAlias = true;
      lineNumberMode = "relNumber";
      searchCase = "smart";
      undoFile.enable = true;
      clipboard = {
        enable = true;
        registers = "unnamedplus";
      };
      globals = {
        mapleader = " ";
        maplocalleader = "\\";
      };
      options = {
        signcolumn = "yes";
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        smartindent = true;
        shiftround = true;
        termguicolors = true;
        cursorline = true;
        scrolloff = 8;
        sidescrolloff = 8;
        showmode = false;
        wrap = false;
        linebreak = true;
        breakindent = true;
        conceallevel = 2;
        fillchars = "fold: ,foldopen:▾,foldclose:▸,diff:╱,eob: ";
        incsearch = true;
        inccommand = "split";
        splitright = true;
        splitbelow = true;
        splitkeep = "screen";
        foldmethod = "expr";
        foldexpr = "v:lua.vim.treesitter.foldexpr()";
        foldlevelstart = 99;
        updatetime = 200;
        timeoutlen = 300;
        ttimeoutlen = 10;
        swapfile = false;
        autoread = true;
        mouse = "a";
        confirm = true;
        virtualedit = "block";
        completeopt = "menuone,noselect,popup";
        pumheight = 12;
        wildmode = "longest:full,full";
        wildoptions = "pum,fuzzy";
        wildignorecase = true;
        laststatus = 3;
        cmdheight = 0;
        showcmdloc = "statusline";
        grepprg = "rg --vimgrep --smart-case";
        grepformat = "%f:%l:%c:%m";
        shortmess = "sIcW";
      };

      # Tools available on PATH inside the nvf Neovim wrapper.
      extraPackages = with pkgs; [
        nixd
        lua-language-server
        pyright
        vtsls
        kotlin-language-server
        jdt-language-server
        marksman
        inputs.qml-language-server.packages.${pkgs.system}.default
        roslyn-ls

        nixfmt-rfc-style
        stylua
        black
        isort
        prettier
        shfmt
        ktlint
        google-java-format
        csharpier
        dotnet-sdk_9
        statix
        deadnix
        python3Packages.debugpy
        netcoredbg
        delve
        lldb
        vscode-js-debug

        tree-sitter
        ripgrep
        fd
      ];

      # Keep full plugin list declarative in Nix, with Lua setup logic in nvim/lua/plugins/*.
      startPlugins =
        with pkgs.vimPlugins;
        [
          tiny-code-action

          (nvim-treesitter.withPlugins (
            p: with p; [
              lua
              vim
              nix
              bash
              fish
              kotlin
              java
              javascript
              typescript
              tsx
              html
              css
              json
              yaml
              python
              markdown
              c_sharp
            ]
          ))
          nvim-treesitter-context
          nvim-treesitter-textobjects

          nvim-lspconfig
          blink-cmp
          luasnip
          friendly-snippets
          copilot-lua
          fidget-nvim
          roslyn-nvim
          tiny-inline-diagnostic-nvim
          nvim-lint
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
          nvim-dap-python
          nvim-nio
          trouble-nvim

          fzf-lua
          oil-nvim
          flash-nvim
          smart-splits-nvim

          lualine-nvim
          statuscol-nvim
          neoscroll-nvim
          nui-nvim
          noice-nvim
          no-neck-pain-nvim
          snacks-nvim
          twilight-nvim

          gitsigns-nvim
          neogit

          nvim-autopairs
          conform-nvim
          dial-nvim
          multicursor-nvim
          # grug-far's upstream test suite is flaky against nightly Neovim.
          (grug-far-nvim.overrideAttrs (_: {
            doCheck = false;
          }))

          mini-nvim
          plenary-nvim
          vim-tmux-navigator
          markview-nvim
        ];

      # Load the existing Lua entrypoint after nvf initializes.
      luaConfigRC.user-config = ''
        dofile(vim.fn.stdpath("config") .. "/init.lua")
      '';
    };
  };

  xdg.configFile."nvf/lua/generated/colors.lua".text = ''
    local M = {
      bg = "${c.bg}",
      raised_background = "${c.raisedBackground}",
      bg_subtle = "${c.bgSubtle}",
      border = "${c.border}",
      fg = "${c.fg}",
      fg_mid = "${c.fgMid}",
      fg_dim = "${c.fgDim}",
      accent = "${c.accent}",
      teal = "${c.teal}",
      purple = "${c.purple}",
      green = "${c.green}",
      yellow = "${c.yellow}",
      red = "${c.red}",
      orange = "${c.orange}",
      magenta = "${c.magenta}",
      selection = "${c.selection}",
      search = "${c.search}",
      trailspace = "${c.trailspace}",
      variant = "${config.lib.stylix.colors.variant}",
      base00 = "${s.base00}",
      base01 = "${s.base01}",
      base02 = "${s.base02}",
      base03 = "${s.base03}",
      base04 = "${s.base04}",
      base05 = "${s.base05}",
      base06 = "${s.base06}",
      base07 = "${s.base07}",
      base08 = "${s.base08}",
      base09 = "${s.base09}",
      base0A = "${s.base0A}",
      base0B = "${s.base0B}",
      base0C = "${s.base0C}",
      base0D = "${s.base0D}",
      base0E = "${s.base0E}",
      base0F = "${s.base0F}",
    }

    return M
  '';

  xdg.configFile."nvf" = {
    source = ../../nvim;
    recursive = true;
  };
}
