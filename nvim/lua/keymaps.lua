local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- ── General ───────────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
map("n", "<C-s>", "<cmd>write<CR>", "Save buffer")
map("i", "<C-s>", "<Esc><cmd>write<CR>", "Save buffer")
map("i", "jk", "<Esc>", "Exit insert mode")
map("n", "U", "<C-r>", "Redo")

-- Keep visual selection when indenting
map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")

-- Move through wrapped lines naturally
map("n", "j", "gj", "Down (visual line)")
map("n", "k", "gk", "Up (visual line)")

-- Centre view after common jumps
map("n", "<C-d>", "<C-d>zz", "Scroll down (centred)")
map("n", "<C-u>", "<C-u>zz", "Scroll up (centred)")
map("n", "n", "nzzzv", "Next match (centred)")
map("n", "N", "Nzzzv", "Prev match (centred)")

-- Paste without losing register
map("x", "<leader>p", '"_dP', "Paste without yanking selection")

-- Delete to black-hole register
map({ "n", "v" }, "<leader>D", '"_d', "Delete without yanking")

-- ── Windows ───────────────────────────────────────────────────────────────
map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "<leader>we", "<C-w>=", "Equalise splits")
map("n", "<leader>wm", "<C-w>_<C-w>|", "Maximise window")

-- Smart-splits navigation (falls back to plain wincmd if unavailable)
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

-- ── Buffers ───────────────────────────────────────────────────────────────
map("n", "<Tab>", "<cmd>bnext<CR>", "Next buffer")
map("n", "<S-Tab>", "<cmd>bprevious<CR>", "Previous buffer")
-- <leader>bd / <leader>bD are set in mini.lua via mini.bufremove

-- ── Quickfix / location list ──────────────────────────────────────────────
map("n", "<leader>qo", "<cmd>copen<CR>", "Open quickfix")
map("n", "<leader>qc", "<cmd>cclose<CR>", "Close quickfix")
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprevious<CR>", "Prev quickfix item")
map("n", "]l", "<cmd>lnext<CR>", "Next location item")
map("n", "[l", "<cmd>lprevious<CR>", "Prev location item")

-- ── Diagnostics ───────────────────────────────────────────────────────────
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

-- ── File navigation (Oil) ─────────────────────────────────────────────────
map("n", "-", "<cmd>Oil<CR>", "Open Oil")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil")

-- ── LSP (supplemental — core LSP maps are in plugins/lsp.lua) ─────────────
map("n", "<leader>li", "<cmd>LspInfo<CR>", "LSP info")
map("n", "<leader>lr", "<cmd>LspRestart<CR>", "LSP restart")

-- ── Git ───────────────────────────────────────────────────────────────────
map("n", "<leader>gg", "<cmd>lua require('gitsigns').preview_hunk()<CR>", "Preview hunk")
map("n", "<leader>gs", "<cmd>lua require('gitsigns').stage_hunk()<CR>", "Stage hunk")
map("n", "<leader>gu", "<cmd>lua require('gitsigns').undo_stage_hunk()<CR>", "Undo stage hunk")
map("n", "<leader>gR", "<cmd>lua require('gitsigns').reset_hunk()<CR>", "Reset hunk")
map("n", "<leader>gb", "<cmd>lua require('gitsigns').blame_line()<CR>", "Blame line")
map("n", "<leader>gB", "<cmd>lua require('gitsigns').blame()<CR>", "Blame buffer")
map("n", "<leader>gd", "<cmd>lua require('gitsigns').diffthis()<CR>", "Diff this")
map("n", "]g", "<cmd>lua require('gitsigns').nav_hunk('next')<CR>", "Next hunk")
map("n", "[g", "<cmd>lua require('gitsigns').nav_hunk('prev')<CR>", "Prev hunk")

-- ── Formatting ────────────────────────────────────────────────────────────
-- <leader>cf is set in plugins/conform.lua

-- ── Toggle helpers ────────────────────────────────────────────────────────
map("n", "<leader>tw", "<cmd>set wrap!<CR>", "Toggle wrap")
map("n", "<leader>ts", "<cmd>set spell!<CR>", "Toggle spell")
map("n", "<leader>tl", "<cmd>set list!<CR>", "Toggle listchars")
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", "Toggle relative numbers")
map("n", "<leader>tc", "<cmd>lua require('mini.cursorword').toggle()<CR>", "Toggle cursorword")
