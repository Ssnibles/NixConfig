-- Flash (search jumps) and the guard that keeps it out of plugin panes.

local flash = require("flash")
local util = require("util")

local function is_main_editor(win)
	local w = win or vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(w)
	if vim.bo[buf].buftype ~= "" or util.is_helper_ft(vim.bo[buf].filetype) then
		return false
	end
	return vim.api.nvim_win_get_config(w).relative == ""
end

flash.setup({
	search = {
		multi_window = true,
		exclude = {
			function(win)
				return not is_main_editor(win)
			end,
		},
	},
})

vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", function()
	if is_main_editor() then
		flash.jump()
	end
end, { desc = "Flash jump" })

vim.keymap.set({ "n", "x", "o" }, "S", function()
	if is_main_editor() then
		flash.treesitter()
	end
end, { desc = "Flash treesitter" })
