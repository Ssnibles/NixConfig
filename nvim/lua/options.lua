-- ============================================================================
-- EDITOR OPTIONS
-- ============================================================================
local opt = vim.opt

-- Line numbers: show absolute on current line, relative on others.
-- Relative numbers make it easy to jump with e.g. `5j` or `12k`.
opt.number = true
opt.relativenumber = true

opt.mouse = "a" -- Enable mouse in all modes (useful for resizing splits)

-- Indentation: 2-space soft tabs (expandtab converts tab key → spaces)
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smartindent = true -- Auto-indent on new lines

-- Appearance
opt.termguicolors = true -- Enable 24-bit colour (required by most themes)
opt.cursorline = true -- Highlight the current line
opt.scrolloff = 8 -- Keep 8 lines visible above/below cursor
opt.signcolumn = "yes" -- Always show the gutter (prevents layout shifts)

-- Floating windows & completion popup.
-- A small blend value adds just enough depth to distinguish floats from the
-- buffer behind them without looking odd. 0 = fully opaque, 100 = invisible.
opt.winblend = 8 -- floating windows (hover docs, fzf, etc.)
opt.pumblend = 8 -- completion popup menu

-- Search
opt.ignorecase = true -- Case-insensitive search by default…
opt.smartcase = true -- …unless the query contains uppercase letters

-- Performance / reliability
opt.updatetime = 200 -- Faster CursorHold events (used by LSP highlights)
opt.undofile = true -- Persist undo history across sessions

-- Use the system clipboard for all yank/paste operations.
-- Requires wl-clipboard (Wayland) or xclip/xsel (X11) to be installed.
opt.clipboard = "unnamedplus"

-- Leader key: <Space> — set before any plugin or keymap loads.
vim.g.mapleader = " "
