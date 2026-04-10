-- Terminal integration via snacks.nvim (actively maintained)

require("snacks").setup({
	terminal = {
		enabled = true,
		win = {
			style = "terminal",
		},
	},
})

local function toggle_terminal(position)
	local ok, snacks = pcall(require, "snacks")
	if not ok then
		vim.notify("snacks.nvim is not available", vim.log.levels.ERROR)
		return
	end
	snacks.terminal.toggle(nil, {
		cwd = vim.fn.getcwd(),
		win = {
			position = position,
		},
	})
end

vim.keymap.set("n", "<leader>tt", function()
	toggle_terminal("bottom")
end, { desc = "Toggle terminal (default)" })
vim.keymap.set("n", "<leader>tb", function()
	toggle_terminal("bottom")
end, { desc = "Toggle terminal (bottom)" })
vim.keymap.set("n", "<leader>tr", function()
	toggle_terminal("right")
end, { desc = "Toggle terminal (right)" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal normal mode" })
