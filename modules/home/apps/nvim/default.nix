{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  c =
    (import ../../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; })
    .withHash;
  s = config.lib.stylix.colors.withHashtag;
  repoRoot = "${config.home.homeDirectory}/NixConfig";
  nvimSrcDir = "${repoRoot}/modules/home/apps/nvim/nvim-src";

  tiny-code-action = pkgs.vimUtils.buildVimPlugin {
    pname = "tiny-code-action";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "rachartier";
      repo = "tiny-code-action.nvim";
      rev = "main";
      sha256 = "sha256-UF9zeO5Uujdt2MEwy2d2Lhk6JRnEN4vrEvYslv0/zaA=";
    };
    doCheck = false;
  };
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
        scrolloff = 999;
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
        timeoutlen = 300;
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
        shortmess = "sIcW";
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

        rust-analyzer
        tinymist
        typst
        typstyle
        neovim-remote

        tree-sitter
        ripgrep
        fd
      ];

      startPlugins = with pkgs.vimPlugins; [
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
            markdown_inline
            latex
            typst
            c_sharp
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
        (grug-far-nvim.overrideAttrs (_: {
          doCheck = false;
        }))

        mini-nvim
        plenary-nvim
        markview-nvim
        typst-preview-nvim
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

  home.activation.removeOldNvfDir = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    if [[ -d "$HOME/.config/nvf" && ! -L "$HOME/.config/nvf" ]]; then
      rm -rf "$HOME/.config/nvf"
    fi
  '';

  home.activation.writeNvfColors = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    colors_dir="${nvimSrcDir}/lua/generated"
    mkdir -p "$colors_dir"
    cat > "$colors_dir/colors.lua" << LUAEOF
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
    LUAEOF
  '';
}
