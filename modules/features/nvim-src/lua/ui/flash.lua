-- Flash search jumps, with a guard that keeps it out of plugin panes.

local util = require("util")
local flash = require("flash")

local M = {}

--- True when `win` is an ordinary editor window: not a float and not a plugin
--- pane, so flash does not label pickers or tool panes.
--- @param win integer?
--- @return boolean
function M.is_main_editor(win)
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
		-- Spell out flash's own list. tbl_deep_extend merges lists by index,
		-- so a lone function would replace "notify" and inherit the rest.
		exclude = {
			"notify",
			"cmp_menu",
			"noice",
			"flash_prompt",
			-- fzf-lua runs fzf in a terminal buffer of filetype "fzf". Its
			-- preview panes are scratch buffers, so the window guard covers
			-- those.
			"fzf",
			function(win)
				return not M.is_main_editor(win)
			end,
		},
	},
})

M.flash = flash

return M
