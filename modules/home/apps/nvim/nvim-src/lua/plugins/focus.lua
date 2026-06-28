-- Focus mode: No Neck Pain + Twilight context dimming

require("no-neck-pain").setup({
	width = 100,
	buffers = {
		left = { enabled = true },
		right = { enabled = true },
	},
})

require("twilight").setup({
	dimming = {
		alpha = 0.25,
	},
	context = 12,
	expand = {
		"function",
		"method",
		"table",
		"if_statement",
	},
})

vim.keymap.set("n", "<leader>zz", "<cmd>NoNeckPain<CR>", { desc = "Toggle center (no neck pain)" })
vim.keymap.set("n", "<leader>zt", "<cmd>Twilight<CR>", { desc = "Toggle twilight (dim inactive)" })
vim.keymap.set("n", "<leader>zf", function()
	vim.cmd("NoNeckPain")
	vim.cmd("Twilight")
end, { desc = "Toggle full focus mode" })
