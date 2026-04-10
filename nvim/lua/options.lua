-- Core editor options
local o, g = vim.opt, vim.g

-- Leaders
g.mapleader = " "
g.maplocalleader = "\\"

-- Line numbers
o.number = true
o.relativenumber = true
o.signcolumn = "yes"

-- Indentation
o.shiftwidth = 2
o.tabstop = 2
o.expandtab = true
o.smartindent = true
o.shiftround = true

-- Display
o.termguicolors = true
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.showmode = false
o.wrap = false
o.linebreak = true
o.breakindent = true
o.conceallevel = 2
o.fillchars = { fold = " ", foldopen = "▾", foldclose = "▸", diff = "╱", eob = " " }

-- Search
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.inccommand = "split"

-- Splits
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"

-- Folds (treesitter-based)
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevelstart = 99

-- Performance
o.updatetime = 200
o.timeoutlen = 300
o.ttimeoutlen = 10
o.undofile = true
o.swapfile = false
o.autoread = true

-- Clipboard and input
o.clipboard = "unnamedplus"
o.mouse = "a"
o.confirm = true
o.virtualedit = "block"

-- Completion and commandline UI
o.completeopt = { "menuone", "noselect", "popup" }
o.pumheight = 12
o.wildmode = "longest:full,full"
o.wildoptions = "pum,fuzzy"
o.wildignorecase = true
o.laststatus = 3
o.cmdheight = 0
o.showcmdloc = "statusline"

-- Grep with ripgrep
o.grepprg = "rg --vimgrep --smart-case"
o.grepformat = "%f:%l:%c:%m"

-- Reduce noise
o.shortmess:append("sIcW")
