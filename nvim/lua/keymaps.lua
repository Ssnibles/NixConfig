-- =============================================================================
-- Keymap Configuration
-- =============================================================================
-- Global keybindings for navigation, editing, and plugin interaction.
-- Uses a helper function for consistent keymap definition.

local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- ── General ────────────────────────────────────────────────────────────────
-- Clear search highlighting with Escape
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- Save buffer with Ctrl+S (normal and insert mode)
map("n", "<C-s>", "<cmd>write<CR>", "Save buffer")
map("i", "<C-s>", "<Esc><cmd>write<CR>", "Save buffer")

-- Exit insert mode with 'jk'
map("i", "jk", "<Esc>", "Exit insert mode")

-- Remap U to redo (default is undo)
map("n", "U", "<C-r>", "Redo")

-- Keep visual selection when indenting
map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")

-- ── Line Navigation ────────────────────────────────────────────────────────
-- Move through wrapped lines naturally (by visual line, not buffer line)
map("n", "j", "gj", "Down (visual line)")
map("n", "k", "gk", "Up (visual line)")

-- Center view after scrolling and search navigation
map("n", "<C-d>", "<C-d>zz", "Scroll down (centred)")
map("n", "<C-u>", "<C-u>zz", "Scroll up (centred)")
map("n", "n", "nzzzv", "Next match (centred)")
map("n", "N", "Nzzzv", "Prev match (centred)")

-- ── Clipboard ──────────────────────────────────────────────────────────────
-- Paste without yanking the current selection
map("x", "<leader>p", '"_dP', "Paste without yanking selection")

-- Delete to black-hole register (don't overwrite clipboard)
map({ "n", "v" }, "<leader>D", '"_d', "Delete without yanking")

-- ── Window Management ──────────────────────────────────────────────────────
-- Split windows vertically and horizontally
map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")

-- Close and equalize windows
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "<leader>we", "<C-w>=", "Equalise splits")

-- Maximize current window
map("n", "<leader>wm", "<C-w>_<C-w>|", "Maximise window")

-- Navigate between windows with Ctrl+hjkl (falls back to wincmd if smart-splits unavailable)
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	map("n", "<C-" .. key .. ">", function()
		local ok, ss = pcall(require, "smart-splits")
		if ok then
			ss["move_cursor_" .. dir]()
		else
			vim.cmd("wincmd " .. key)
		end
	end, "Move to " .. dir .. " window")
end

-- ── Buffer Navigation ──────────────────────────────────────────────────────
-- Cycle through buffers with Tab and Shift+Tab
map("n", "<Tab>", "<cmd>bnext<CR>", "Next buffer")
map("n", "<S-Tab>", "<cmd>bprevious<CR>", "Previous buffer")

-- Buffer delete keymaps are defined in mini.lua via mini.bufremove

-- ── Quickfix and Location List ────────────────────────────────────────────
-- Open and close quickfix window
map("n", "<leader>qo", "<cmd>copen<CR>", "Open quickfix")
map("n", "<leader>qc", "<cmd>cclose<CR>", "Close quickfix")

-- Navigate quickfix and location list items
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprevious<CR>", "Prev quickfix item")
map("n", "]l", "<cmd>lnext<CR>", "Next location item")
map("n", "[l", "<cmd>lprevious<CR>", "Prev location item")

-- ── Diagnostics ────────────────────────────────────────────────────────────
-- Show diagnostic float under cursor
map("n", "<leader>dd", vim.diagnostic.open_float, "Show diagnostic float")

-- Send diagnostics to location list
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics → loclist")

-- Jump between diagnostics with float preview
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "Prev diagnostic")

-- Jump between errors specifically
map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Next error")
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Prev error")

-- ── File Navigation (Oil) ─────────────────────────────────────────────────
-- Open Oil file explorer (both - and leader+o)
map("n", "-", "<cmd>Oil<CR>", "Open Oil")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil")

-- ── LSP ────────────────────────────────────────────────────────────────────
-- Show LSP client info and restart LSP servers
map("n", "<leader>li", "<cmd>LspInfo<CR>", "LSP info")
map("n", "<leader>lr", "<cmd>LspRestart<CR>", "LSP restart")

-- Core LSP keymaps (gd, gr, K, etc.) are defined in plugins/lsp.lua

-- ── Git (Gitsigns) ────────────────────────────────────────────────────────
-- Preview, stage, and reset git hunks
map("n", "<leader>gg", "<cmd>lua require('gitsigns').preview_hunk()<CR>", "Preview hunk")
map("n", "<leader>gs", "<cmd>lua require('gitsigns').stage_hunk()<CR>", "Stage hunk")
map("n", "<leader>gu", "<cmd>lua require('gitsigns').undo_stage_hunk()<CR>", "Undo stage hunk")
map("n", "<leader>gR", "<cmd>lua require('gitsigns').reset_hunk()<CR>", "Reset hunk")

-- Git blame functionality
map("n", "<leader>gb", "<cmd>lua require('gitsigns').blame_line()<CR>", "Blame line")
map("n", "<leader>gB", "<cmd>lua require('gitsigns').blame()<CR>", "Blame buffer")

-- Git diff and hunk navigation
map("n", "<leader>gd", "<cmd>lua require('gitsigns').diffthis()<CR>", "Diff this")
map("n", "]g", "<cmd>lua require('gitsigns').nav_hunk('next')<CR>", "Next hunk")
map("n", "[g", "<cmd>lua require('gitsigns').nav_hunk('prev')<CR>", "Prev hunk")

-- ── Toggle Helpers ────────────────────────────────────────────────────────
-- Toggle various editor options
map("n", "<leader>tw", "<cmd>set wrap!<CR>", "Toggle wrap")
map("n", "<leader>ts", "<cmd>set spell!<CR>", "Toggle spell")
map("n", "<leader>tl", "<cmd>set list!<CR>", "Toggle listchars")
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", "Toggle relative numbers")
map("n", "<leader>tc", "<cmd>lua require('mini.cursorword').toggle()<CR>", "Toggle cursorword")
