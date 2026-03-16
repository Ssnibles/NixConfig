-- =============================================================================
-- Keymap Configuration
-- =============================================================================
local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- General
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
map("n", "<C-s>", "<cmd>write<CR>", "Save buffer")
map("i", "<C-s>", "<Esc><cmd>write<CR>", "Save buffer")
map("i", "jk", "<Esc>", "Exit insert mode")
map("n", "U", "<C-r>", "Redo")
map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")

-- Navigation
map("n", "j", "gj", "Down (visual line)")
map("n", "k", "gk", "Up (visual line)")
map("n", "<C-d>", "<C-d>zz", "Scroll down (centred)")
map("n", "<C-u>", "<C-u>zz", "Scroll up (centred)")
map("n", "n", "nzzzv", "Next match (centred)")
map("n", "N", "Nzzzv", "Prev match (centred)")

-- Clipboard
map("x", "<leader>p", '"_dP', "Paste without yanking selection")
map({ "n", "v" }, "<leader>D", '"_d', "Delete without yanking")

-- Windows
map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "<leader>we", "<C-w>=", "Equalise splits")
map("n", "<leader>wm", "<C-w>_<C-w>|", "Maximise window")

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

-- Buffers
map("n", "<Tab>", "<cmd>bnext<CR>", "Next buffer")
map("n", "<S-Tab>", "<cmd>bprevious<CR>", "Previous buffer")

-- Quickfix
map("n", "<leader>qo", "<cmd>copen<CR>", "Open quickfix")
map("n", "<leader>qc", "<cmd>cclose<CR>", "Close quickfix")
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprevious<CR>", "Prev quickfix item")
map("n", "]l", "<cmd>lnext<CR>", "Next location item")
map("n", "[l", "<cmd>lprevious<CR>", "Prev location item")

-- Diagnostics
map("n", "<leader>dd", vim.diagnostic.open_float, "Show diagnostic float")
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics → loclist")
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "Prev diagnostic")
map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Next error")
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Prev error")

-- File Navigation
map("n", "-", "<cmd>Oil<CR>", "Open Oil")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil")

-- LSP
map("n", "<leader>li", "<cmd>LspInfo<CR>", "LSP info")
map("n", "<leader>lr", "<cmd>LspRestart<CR>", "LSP restart")

-- Git
map("n", "<leader>gg", function()
	require("gitsigns").preview_hunk()
end, "Preview hunk")
map("n", "<leader>gs", function()
	require("gitsigns").stage_hunk()
end, "Stage hunk")
map("n", "<leader>gu", function()
	require("gitsigns").undo_stage_hunk()
end, "Undo stage hunk")
map("n", "<leader>gR", function()
	require("gitsigns").reset_hunk()
end, "Reset hunk")
map("n", "<leader>gb", function()
	require("gitsigns").blame_line()
end, "Blame line")
map("n", "<leader>gd", function()
	require("gitsigns").diffthis()
end, "Diff this")
map("n", "]g", function()
	require("gitsigns").nav_hunk("next")
end, "Next hunk")
map("n", "[g", function()
	require("gitsigns").nav_hunk("prev")
end, "Prev hunk")

-- Toggles
map("n", "<leader>tw", "<cmd>set wrap!<CR>", "Toggle wrap")
map("n", "<leader>ts", "<cmd>set spell!<CR>", "Toggle spell")
map("n", "<leader>tl", "<cmd>set list!<CR>", "Toggle listchars")
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", "Toggle relative numbers")
map("n", "<leader>tc", function()
	require("mini.cursorword").toggle()
end, "Toggle cursorword")
