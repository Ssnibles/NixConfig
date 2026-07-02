{
  config,
  lib,
  pkgs,
  inputs,
  semanticColors,
  ...
}:
let
  c = semanticColors { colors = config.lib.stylix.colors; };
  s = config.lib.stylix.colors.withHashtag;
  repoRoot = "${config.home.homeDirectory}/NixConfig";
  nvimSrcDir = "${repoRoot}/modules/home/apps/nvim/nvim-src";

  colorsLua = ''
    local M = {
      bg = "${c.withHash.bg}",
      raised_background = "${c.withHash.raisedBackground}",
      bg_subtle = "${c.withHash.bgSubtle}",
      border = "${c.withHash.border}",
      fg = "${c.withHash.fg}",
      fg_mid = "${c.withHash.fgMid}",
      fg_dim = "${c.withHash.fgDim}",
      accent = "${c.withHash.accent}",
      teal = "${c.withHash.teal}",
      purple = "${c.withHash.purple}",
      green = "${c.withHash.green}",
      yellow = "${c.withHash.yellow}",
      red = "${c.withHash.red}",
      orange = "${c.withHash.orange}",
      magenta = "${c.withHash.magenta}",
      selection = "${c.withHash.selection}",
      search = "${c.withHash.search}",
      trailspace = "${c.withHash.trailspace}",
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
in
{
  programs.nvf = {
    enable = true;
    defaultEditor = true;

    settings.vim = {
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
        fillchars = "fold: ,foldopen:▾,foldclose:▸,diff:╱,eob: ,vert:│,horiz:─";
        incsearch = true;
        inccommand = "split";
        splitright = true;
        splitbelow = true;
        splitkeep = "screen";
        foldmethod = "expr";
        foldexpr = "v:lua.vim.treesitter.foldexpr()";
        foldlevelstart = 99;
        updatetime = 200;
        timeoutlen = 400;
        ttimeoutlen = 10;
        swapfile = false;
        autoread = true;
        mouse = "a";
        mousemodel = "extend";
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
        shortmess = "sIcWF";
      };

      extraPackages = with pkgs; [
        nixd
        lua-language-server
        pyright
        vtsls
        kotlin-language-server
        jdt-language-server
        marksman
        ltex-ls-plus
        inputs.qml-language-server.packages.${pkgs.stdenv.hostPlatform.system}.default
        roslyn-ls

        nixfmt
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

        rust-analyzer
        rustfmt
        cargo
        rustc
        clippy
        tinymist
        typst
        typstyle
        neovim-remote

        tree-sitter
        ripgrep
        fd
      ];

      startPlugins = with pkgs.vimPlugins; [
        pkgs.tiny-code-action

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
            markdown_inline
            latex
            typst
            c_sharp
            rust
          ]
        ))
        nvim-treesitter-context
        nvim-treesitter-textobjects

        blink-cmp
        blink-cmp-spell
        luasnip
        friendly-snippets
        copilot-lua
        fidget-nvim
        roslyn-nvim
        nvim-lint
        nvim-dap
        nvim-dap-ui
        nvim-dap-virtual-text
        nvim-dap-python
        nvim-nio
        trouble-nvim

        fzf-lua
        # oil-nvim
        fyler-nvim
        flash-nvim
        smart-splits-nvim

        lualine-nvim
        statuscol-nvim
        nui-nvim
        no-neck-pain-nvim
        snacks-nvim
        twilight-nvim

        gitsigns-nvim
        neogit

        conform-nvim
        dial-nvim

        (grug-far-nvim.overrideAttrs (_: {
          doCheck = false;
        }))

        mini-nvim
        plenary-nvim
        markview-nvim
        typst-preview-nvim
        rustaceanvim
      ];

      luaConfigRC.user-config = ''
        dofile(vim.fn.stdpath("config") .. "/init.lua")
      '';
    };
  };

  xdg.configFile."nvf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${nvimSrcDir}";
    force = true;
  };

  # Write generated colors directly into the repo checkout so the symlink
  # picks them up without an imperative activation script.
  home.file."NixConfig/modules/home/apps/nvim/nvim-src/lua/generated/colors.lua" = {
    text = colorsLua;
    force = true;
  };
}
