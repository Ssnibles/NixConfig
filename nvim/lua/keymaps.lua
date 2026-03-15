local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- ── General ───────────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
map("n", "<C-s>", "<cmd>write<CR>", "Save buffer")
map("i", "<C-s>", "<Esc><cmd>write<CR>", "Save buffer")
map("i", "jk", "<Esc>", "Exit insert mode")

-- ── Windows ───────────────────────────────────────────────────────────────
map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "<leader>we", "<C-w>=", "Equalise splits")

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
map("n", "<leader>bd", "<cmd>bdelete<CR>", "Delete buffer")

-- ── File navigation (Oil) ─────────────────────────────────────────────────
map("n", "-", "<cmd>Oil<CR>", "Open Oil")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil")
