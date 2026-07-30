{ self, inputs, ... }:
{
  flake.nixosModules.neovim =
    { pkgs, lib, config, ... }:
    {
      imports = [
        inputs.nvf.nixosModules.default
      ];

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

            neovide_font_family = "JetBrainsMono Nerd Font";
            neovide_font_size = 12;
            neovide_padding_top = 20;
            neovide_padding_bottom = 20;
            neovide_padding_left = 20;
            neovide_padding_right = 20;
            neovide_refresh_rate = 60;
            neovide_idle = true;
            neovide_vsync = true;
            neovide_cursor_vfx_mode = "";
            neovide_cursor_animation_length = 0.0;
            neovide_scroll_animation_length = 0.08;
            neovide_floating_blur = false;
            neovide_confirm_quit = true;
            neovide_remember_window_size = true;
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
            showmode = false;
            wrap = false;
            linebreak = true;
            breakindent = true;
            conceallevel = 2;
            incsearch = true;
            inccommand = "split";
            splitright = true;
            splitbelow = true;
            splitkeep = "cursor";
            foldmethod = "expr";
            foldexpr = "v:lua.vim.treesitter.foldexpr()";
            foldlevelstart = 99;
            ttimeoutlen = 10;
            swapfile = false;
            autoread = true;
            mouse = "a";
            mousemodel = "extend";
            confirm = true;
            virtualedit = "block";
            pumheight = 12;
            wildmode = "longest:full,full";
            wildoptions = "fuzzy";
            wildignorecase = true;
            laststatus = 3;
            cmdheight = 0;
            showcmdloc = "statusline";
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
            roslyn-ls

            nixfmt
            stylua
            black
            isort
            prettierd
            shfmt
            ktlint
            google-java-format
            csharpier
            dotnet-sdk_9
            statix
            deadnix

            rust-analyzer
            rustfmt
            cargo
            rustc
            clippy
            tinymist
            typst
            typstyle
            neovim-remote

            python3Packages.debugpy
            netcoredbg
            delve
            lldb
            vscode-js-debug

            tree-sitter
          ];

          startPlugins = with pkgs.vimPlugins; [
            nvim-treesitter.withAllGrammars
            nvim-treesitter-context
            nvim-treesitter-textobjects

            blink-cmp
            blink-cmp-spell
            luasnip
            friendly-snippets
            copilot-lua
            nvim-lint
            roslyn-nvim

            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            nvim-dap-python
            nvim-nio

            fzf-lua
            oil-nvim
            flash-nvim
            smart-splits-nvim

            nui-nvim

            gitsigns-nvim
            neogit

            grug-far-nvim

            mini-nvim
            plenary-nvim
            typst-preview-nvim
            rustaceanvim

            tiny-inline-diagnostic-nvim
          ];

          luaConfigRC.user-config = ''
            dofile(vim.fn.stdpath("config") .. "/init.lua")
          '';
        };
      };

      system.activationScripts.nvf-config = ''
        mkdir -p /home/${config.username}/.config
        ln -sfn /home/${config.username}/NixConfig/modules/features/nvim-src /home/${config.username}/.config/nvim
        ln -sfn /home/${config.username}/NixConfig/modules/features/nvim-src /home/${config.username}/.config/nvf
      '';
    };
}
