-- =============================================================================
-- Vim Options Configuration
-- =============================================================================
-- Core editor settings that affect behavior, appearance, and performance.
-- These load first so plugins can override if needed.
-- =============================================================================

local opt = vim.opt

-- ── Leader Keys ────────────────────────────────────────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ── Line Numbers ───────────────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true

-- ── Indentation ────────────────────────────────────────────────────────────
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.shiftround = true

-- ── Appearance ─────────────────────────────────────────────────────────────
opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.winblend = 0
opt.pumblend = 0
opt.showmode = false
opt.conceallevel = 2
opt.concealcursor = "nc"

-- ── Fill Characters ────────────────────────────────────────────────────────
opt.fillchars = {
	fold = " ",
	foldopen = "▾",
	foldclose = "▸",
	diff = "╱",
	eob = " ",
}

-- ── Search ─────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.inccommand = "split"

-- ── Window Splits ──────────────────────────────────────────────────────────
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- ── Folds ──────────────────────────────────────────────────────────────────
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99

-- ── Performance ────────────────────────────────────────────────────────────
opt.updatetime = 200
opt.timeoutlen = 500
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- ── Text Behavior ──────────────────────────────────────────────────────────
opt.wrap = false
opt.linebreak = true
opt.breakindent = true

-- ── Clipboard & Mouse ──────────────────────────────────────────────────────
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.confirm = true
opt.virtualedit = "block"

-- ── Grep ───────────────────────────────────────────────────────────────────
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

-- ── Messages ───────────────────────────────────────────────────────────────
opt.shortmess:append("sIc")
