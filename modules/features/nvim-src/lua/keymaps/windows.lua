-- Windows, splits, buffers, tabs, the quickfix list and the terminal.
local map = vim.keymap.set
local splits = require("ui.splits")
-- Window navigation and resizing
map("n", "<C-h>", splits.move_cursor_left, { desc = "Move left" })
map("n", "<C-j>", splits.move_cursor_down, { desc = "Move down" })
map("n", "<C-k>", splits.move_cursor_up, { desc = "Move up" })
map("n", "<C-l>", splits.move_cursor_right, { desc = "Move right" })
map("n", "<C-S-h>", splits.resize_left, { desc = "Resize left" })
map("n", "<C-S-j>", splits.resize_down, { desc = "Resize down" })
map("n", "<C-S-k>", splits.resize_up, { desc = "Resize up" })
map("n", "<C-S-l>", splits.resize_right, { desc = "Resize right" })
-- Splits
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wq", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Only window" })
map("n", "<leader>wz", function()
	if vim.t.zoomed then
		vim.cmd.tabclose()
		vim.t.zoomed = false
	elseif #vim.api.nvim_tabpage_list_wins(0) > 1 then
		vim.cmd("tab split")
		vim.t.zoomed = true
	end
end, { desc = "Toggle maximise/zoom window" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalise windows" })
map("n", "<leader>wh", "<C-w>H", { desc = "Move window left" })
map("n", "<leader>wl", "<C-w>L", { desc = "Move window right" })
map("n", "<leader>wj", "<C-w>J", { desc = "Move window down" })
map("n", "<leader>wk", "<C-w>K", { desc = "Move window up" })
-- Buffers
map("n", "<leader>bd", function()
	require("mini.bufremove").delete(0, false)
end, { desc = "Delete buffer" })
map("n", "<leader>bo", function()
	local current = vim.api.nvim_get_current_buf()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
			vim.api.nvim_buf_delete(buf, { unload = false })
		end
	end
end, { desc = "Close other buffers" })
map("n", "<leader>`", "<cmd>b#<CR>", { desc = "Alternate buffer" })
map("n", "<C-Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<C-S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
-- Tabs
map("n", "]t", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[t", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>Tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>Tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
-- Quickfix and location list. [q/]q and [l/]l are built-in and honour a count.
map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "<leader>qf", function()
	vim.cmd(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and "cclose" or "copen")
end, { desc = "Toggle quickfix list" })
map("n", "<leader>ql", "<cmd>lopen<CR>", { desc = "Open location list" })
map("n", "<leader>qL", "<cmd>lclose<CR>", { desc = "Close location list" })
-- Terminal
for _, entry in ipairs({
	{ "<leader>tt", "bottom", "Toggle terminal (bottom)" },
	{ "<leader>tr", "right", "Toggle terminal (right)" },
	{ "<leader>tf", "float", "Toggle terminal (float)" },
}) do
	map("n", entry[1], function()
		require("terminal").toggle(entry[2])
	end, { desc = entry[3] })
end
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
