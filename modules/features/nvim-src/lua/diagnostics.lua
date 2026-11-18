-- Diagnostics: display settings, inline virtual text and progress messages.

local util = require("util")
local tid = require("tiny-inline-diagnostic")

local M = {}

vim.diagnostic.config({
	virtual_text = false,
	underline = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "×",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.HINT] = "•",
			[vim.diagnostic.severity.INFO] = "•",
		},
	},
	severity_sort = true,
	float = { border = "rounded", source = "if_many", max_width = 70 },
	update_in_insert = false,
})

tid.setup({
	preset = "modern",
	transparent_bg = false,
	hi = {
		error = "DiagnosticError",
		warn = "DiagnosticWarn",
		info = "DiagnosticInfo",
		hint = "DiagnosticHint",
		arrow = "NonText",
		background = "CursorLine",
		mixing_color = "Normal",
	},
	options = {
		show_source = {
			enabled = true,
			if_many = false,
		},
		show_code = true,
		multilines = {
			enabled = true,
			always_show = false,
		},
		show_all_diags_on_cursorline = true,
		enable_on_insert = false,
		overflow = { mode = "wrap" },
		break_line = {
			enabled = true,
			after = 40,
		},
		virt_texts = { priority = 2048 },
	},
})

-- Only the LSP progress display is used. Notifications are ordinary messages,
-- so they reach `:messages` and the message window like anything else. Progress
-- is drawn in the notification window, so frame that like the other floats.
require("fidget").setup({
	notification = {
		window = {
			normal_hl = "",
			winblend = 0,
			border = "rounded",
		},
	},
})

--- Toggle diagnostics for every buffer, including the inline text.
function M.toggle()
	local enabled = not vim.diagnostic.is_enabled()
	vim.diagnostic.enable(enabled)
	if enabled then
		tid.enable()
	else
		tid.disable()
	end
	util.notify_toggle("Diagnostics", enabled)
end

--- Toggle the inline virtual text only.
function M.toggle_inline()
	tid.toggle()
end

return M
