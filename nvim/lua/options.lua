-- =============================================================================
-- Vim Options Configuration
-- =============================================================================
-- Core editor settings that affect behavior, appearance, and performance.
-- These load first so plugins can override if needed.
--
-- Categories:
--   - Leader keys (prefix for custom bindings)
--   - Line numbers and appearance
--   - Indentation behavior
--   - Search and navigation
--   - Performance optimizations
--   - Text behavior and clipboard
-- =============================================================================
local opt = vim.opt

-- ── Leader Keys ────────────────────────────────────────────────────────────
-- Space is the leader key for most custom commands
vim.g.mapleader = " "
-- Backslash for local leader (buffer-specific bindings)
vim.g.maplocalleader = "\\"

-- ── Line Numbers ───────────────────────────────────────────────────────────
opt.number = true -- Show absolute line numbers
opt.relativenumber = true -- Show relative line numbers for easy navigation

-- ── Indentation ────────────────────────────────────────────────────────────
opt.shiftwidth = 2 -- Number of spaces for auto-indent
opt.tabstop = 2 -- Number of spaces for tab character
opt.expandtab = true -- Convert tabs to spaces
opt.smartindent = true -- Smart auto-indenting
opt.shiftround = true -- Round indent to multiple of shiftwidth

-- ── Appearance ─────────────────────────────────────────────────────────────
opt.termguicolors = true -- True color support
opt.cursorline = true -- Highlight current line
opt.scrolloff = 8 -- Lines of context above/below cursor
opt.sidescrolloff = 8 -- Columns of context left/right of cursor
opt.signcolumn = "yes" -- Always show sign column (for diagnostics/git)
opt.winblend = 0 -- Transparency for floating windows
opt.pumblend = 0 -- Transparency for popup menu
opt.showmode = false -- Don't show mode (statusline handles this)
opt.conceallevel = 2 -- Hide markup symbols (markdown, etc.)
opt.concealcursor = "nc" -- Conceal in normal and command mode

-- ── Fill Characters ────────────────────────────────────────────────────────
-- Custom characters for folds, diffs, and end-of-buffer
opt.fillchars = {
	fold = " ",
	foldopen = "▾",
	foldclose = "▸",
	diff = "╱",
	eob = " ", -- Empty lines at end of buffer
}

-- ── Search ─────────────────────────────────────────────────────────────────
opt.ignorecase = true -- Case-insensitive search
opt.smartcase = true -- Case-sensitive if uppercase in pattern
opt.hlsearch = true -- Highlight search results
opt.inccommand = "split" -- Show substitute preview in split

-- ── Window Splits ──────────────────────────────────────────────────────────
opt.splitright = true -- New vertical splits open on the right
opt.splitbelow = true -- New horizontal splits open below
opt.splitkeep = "screen" -- Keep cursor position when splitting

-- ── Folds ──────────────────────────────────────────────────────────────────
opt.foldmethod = "expr" -- Use expression for folding (treesitter)
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99 -- Start with all folds open

-- ── Performance ────────────────────────────────────────────────────────────
opt.updatetime = 200 -- Faster completion and git signs
opt.timeoutlen = 500 -- Time to wait for mapped sequence
opt.undofile = true -- Persistent undo
opt.swapfile = false -- No swap files
opt.backup = false -- No backup files
opt.writebackup = false -- No write backup files

-- ── Text Behavior ──────────────────────────────────────────────────────────
opt.wrap = false -- Don't wrap lines
opt.linebreak = true -- Break at word boundaries when wrapping
opt.breakindent = true -- Maintain indent on wrapped lines

-- ── Clipboard & Mouse ──────────────────────────────────────────────────────
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.mouse = "a" -- Enable mouse in all modes
opt.confirm = true -- Confirm unsaved changes
opt.virtualedit = "block" -- Allow cursor past end of line in visual block

-- ── Grep ───────────────────────────────────────────────────────────────────
opt.grepprg = "rg --vimgrep --smart-case" -- Use ripgrep for grep
opt.grepformat = "%f:%l:%c:%m" -- Parse ripgrep output

-- ── Messages ───────────────────────────────────────────────────────────────
-- Shorten message display (s=skip search hit, I=skip intro, c=quickfix)
opt.shortmess:append("sIc")
