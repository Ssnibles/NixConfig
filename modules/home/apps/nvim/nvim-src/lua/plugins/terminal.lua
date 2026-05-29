-- Terminal integration via snacks.nvim.
-- snacks.setup() is called by ui.lua; here we just define keymaps.

local function toggle_terminal(position)
	local ok, snacks = pcall(require, "snacks")
	if not ok then
		vim.notify("snacks.nvim is not available", vim.log.levels.ERROR)
		return
	end
	snacks.terminal.toggle(nil, {
		cwd = vim.fn.getcwd(),
		win = { position = position },
	})
end

vim.keymap.set("n", "<leader>tt", function()
	toggle_terminal("bottom")
end, { desc = "Toggle terminal" })

vim.keymap.set("n", "<leader>tr", function()
	toggle_terminal("right")
end, { desc = "Toggle terminal (right)" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal normal mode" })
