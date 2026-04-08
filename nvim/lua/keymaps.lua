-- =============================================================================
-- Keymaps Configuration
-- =============================================================================
-- Core keyboard mappings for editor navigation, text manipulation, and workflows.
-- Organized by function for easy discovery and modification.
--
-- Categories:
--   • General (search, insert mode, redo)
--   • Visual mode (indentation, line movement)
--   • Navigation (visual lines, centered scrolling)
--   • Registers & Clipboard (paste/delete without yanking)
--   • Window Management (splits, navigation)
--   • Buffer Navigation (next/previous)
--   • Quickfix & Location Lists
--   • Diagnostics (LSP)
--   • File Explorer (Oil)
--   • LSP Actions
--   • Toggles (UI options)
--
-- Note: Plugin-specific keymaps (fzf, neogit, etc.) are defined in their
-- respective plugin configuration files under lua/plugins/*.lua
-- =============================================================================

-- ── Helper Function ──────────────────────────────────────────────────────────
-- Wrapper for vim.keymap.set with default options
-- All mappings are noremap (non-recursive) and silent by default
local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- =============================================================================
-- GENERAL MAPPINGS
-- =============================================================================

-- Clear search highlight with Escape (normal mode)
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- Quick exit from insert mode (alternative to Escape)
map("i", "jk", "<Esc>", "Exit insert mode")

-- Redo with U (more intuitive than Ctrl-R)
map("n", "U", "<C-r>", "Redo")

-- =============================================================================
-- VISUAL MODE EDITING
-- =============================================================================

-- Maintain visual selection after indent/outdent
map("v", "<", "<gv", "Indent left (keep selection)")
map("v", ">", ">gv", "Indent right (keep selection)")

-- Move selected lines up/down (with automatic reindentation)
map("v", "J", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "K", ":m '<-2<CR>gv=gv", "Move selection up")

-- =============================================================================
-- NAVIGATION & SCROLLING
-- =============================================================================

-- Navigate by visual lines (useful for wrapped text)
map("n", "j", "gj", "Down (visual line)")
map("n", "k", "gk", "Up (visual line)")

-- Centered scrolling (keep cursor in middle of screen)
map("n", "<C-d>", "<C-d>zz", "Scroll down (centered)")
map("n", "<C-u>", "<C-u>zz", "Scroll up (centered)")

-- Centered search navigation (keep matches in middle of screen)
map("n", "n", "nzzzv", "Next search match (centered)")
map("n", "N", "Nzzzv", "Prev search match (centered)")

-- =============================================================================
-- REGISTERS & CLIPBOARD
-- =============================================================================

-- Paste over selection without yanking replaced text (black hole register)
map("x", "<leader>p", '"_dP', "Paste without yanking selection")

-- Delete to black hole register (preserves yank register)
map({ "n", "v" }, "<leader>D", '"_d', "Delete without yanking")

-- =============================================================================
-- WINDOW MANAGEMENT
-- =============================================================================

map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "<leader>we", "<C-w>=", "Equalize window sizes")
map("n", "<leader>wm", "<C-w>_<C-w>|", "Maximize current window")

-- Seamless Tmux/Neovim navigation (requires vim-tmux-navigator plugin)
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", "Navigate left (Tmux-aware)")
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", "Navigate down (Tmux-aware)")
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", "Navigate up (Tmux-aware)")
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", "Navigate right (Tmux-aware)")

-- =============================================================================
-- BUFFER NAVIGATION
-- =============================================================================

map("n", "<C-Tab>", "<cmd>bnext<CR>", "Next buffer")
map("n", "<C-S-Tab>", "<cmd>bprevious<CR>", "Previous buffer")

-- =============================================================================
-- QUICKFIX & LOCATION LISTS
-- =============================================================================

-- Quickfix list (project-wide errors, search results, etc.)
map("n", "<leader>qo", "<cmd>copen<CR>", "Open quickfix list")
map("n", "<leader>qc", "<cmd>cclose<CR>", "Close quickfix list")
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprevious<CR>", "Previous quickfix item")

-- Location list (buffer-local errors, diagnostics)
map("n", "]l", "<cmd>lnext<CR>", "Next location list item")
map("n", "[l", "<cmd>lprevious<CR>", "Previous location list item")

-- =============================================================================
-- DIAGNOSTICS (LSP)
-- =============================================================================

-- Show diagnostic details in floating window
map("n", "<leader>dd", vim.diagnostic.open_float, "Show diagnostic details")

-- Send all diagnostics to location list
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics → location list")

-- Navigate diagnostics with ]d/[d (all severities)
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")

map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "Previous diagnostic")

-- Navigate errors only with ]e/[e (ERROR severity)
map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Next error")

map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Previous error")

-- =============================================================================
-- FILE EXPLORER (Oil)
-- =============================================================================

-- Open Oil file manager (directory buffer approach)
map("n", "-", "<cmd>Oil<CR>", "Open Oil (parent directory)")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil (parent directory)")

-- =============================================================================
-- LSP ACTIONS
-- =============================================================================

local function code_action()
	local ok, tiny = pcall(require, "tiny-code-action")
	if ok then
		tiny.code_action()
		return
	end
	vim.notify(
		"tiny-code-action not available; falling back to built-in code actions.",
		vim.log.levels.WARN,
		{ title = "LSP" }
	)
	vim.lsp.buf.code_action()
end

map({ "n", "v" }, "<leader>ca", code_action, "Code action")

-- LSP server management
map("n", "<leader>li", "<cmd>LspInfo<CR>", "LSP server info")
map("n", "<leader>lr", "<cmd>LspRestart<CR>", "Restart LSP server")

-- =============================================================================
-- TOGGLES (UI OPTIONS)
-- =============================================================================

-- Text display
map("n", "<leader>tw", "<cmd>set wrap!<CR>", "Toggle line wrapping")
map("n", "<leader>ts", "<cmd>set spell!<CR>", "Toggle spell check")
map("n", "<leader>tl", "<cmd>set list!<CR>", "Toggle invisible characters")
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", "Toggle relative line numbers")

-- Plugin features
map("n", "<leader>tc", function()
	require("mini.cursorword").toggle()
end, "Toggle cursor word highlight")

-- LSP inlay hints (type annotations, parameter names)
map("n", "<leader>th", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
	vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
end, "Toggle LSP inlay hints")
