-- Trouble: better diagnostics/quickfix/location list UI
local trouble = require("trouble")

trouble.setup({
	focus = true,
	auto_open = false,
	auto_close = true,
	auto_preview = false,
	preview = {
		type = "main",
		scratch = true,
	},
	win = {
		border = "rounded",
	},
})

local map = vim.keymap.set
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Trouble diagnostics" })
map("n", "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Trouble buffer diagnostics" })
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<CR>", { desc = "Trouble quickfix" })
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", { desc = "Trouble loclist" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", { desc = "Trouble symbols" })
