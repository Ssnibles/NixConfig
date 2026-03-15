local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation (2-space soft tabs)
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smartindent = true

-- Appearance
opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.winblend = 8 -- floating window transparency
opt.pumblend = 8 -- completion popup transparency

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Performance / reliability
opt.updatetime = 200
opt.undofile = true

-- System clipboard (requires wl-clipboard on Wayland)
opt.clipboard = "unnamedplus"

opt.mouse = "a"
