-- =============================================================================
-- Vim Options Configuration
-- =============================================================================
-- All vim.opt settings for editor behavior, appearance, and performance.
-- These load before any plugins to establish base behavior.
local opt = vim.opt
-- Leader key configuration (space for normal, backslash for local)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- ── Line Numbers ───────────────────────────────────────────────────────────
-- Show absolute line numbers with relative numbers for easy navigation
opt.number = true
opt.relativenumber = true
-- ── Indentation ────────────────────────────────────────────────────────────
-- 2-space soft tabs with smart indentation behavior
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.shiftround = true
-- ── Appearance ─────────────────────────────────────────────────────────────
-- Enable true color support and visual enhancements
opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"
-- Disable transparency for flat, opaque UI (no shadows or blending)
opt.winblend = 0
opt.pumblend = 0
-- Hide mode display (lualine shows mode in statusline)
opt.showmode = false
-- Conceal markup characters in markdown and similar filetypes
opt.conceallevel = 2
opt.concealcursor = "nc"
-- Custom fill characters for folds, diffs, and end-of-buffer
opt.fillchars = {
	fold = " ",
	foldopen = "▾",
	foldclose = "▸",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}
-- List characters for whitespace visualization
opt.list = false
-- opt.listchars = {
-- 	trail = "·",
-- 	nbspace = "␣",
-- 	extends = "›",
-- 	precedes = "‹",
-- 	tab = "  ",
-- }
-- ── Search ─────────────────────────────────────────────────────────────────
-- Case-insensitive search with smart case exception
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.inccommand = "split"
-- ── Window Splits ──────────────────────────────────────────────────────────
-- New splits open to the right and below
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
-- ── Folds ──────────────────────────────────────────────────────────────────
-- Use treesitter for fold expressions, start with all folds open
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99
-- ── Performance ────────────────────────────────────────────────────────────
-- Faster update times for plugins and LSP
opt.updatetime = 200
opt.timeoutlen = 400
-- Enable persistent undo history
opt.undofile = true
-- Disable swap and backup files
opt.swapfile = false
opt.backup = false
opt.writebackup = false
-- ── Text Wrapping ──────────────────────────────────────────────────────────
-- Disable wrapping by default (can toggle per-filetype)
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
-- ── Miscellaneous ──────────────────────────────────────────────────────────
-- Use system clipboard for all yank/delete operations
opt.clipboard = "unnamedplus"
-- Enable mouse support in all modes
opt.mouse = "a"
-- Confirm before exiting with unsaved changes
opt.confirm = true
-- Allow free cursor movement in visual block mode
opt.virtualedit = "block"
-- Configure grep to use ripgrep with vimgrep output format
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"
-- Suppress startup and completion messages
opt.shortmess:append("sIc")
