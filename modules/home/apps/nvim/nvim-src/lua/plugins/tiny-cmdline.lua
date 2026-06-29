local c = require("theme").colors

vim.g.tiny_cmdline = {
	width = {
		value = "60%",
		min = 40,
		max = 80,
	},
	position = {
		x = "50%",
		y = "50%",
	},
	border = "rounded",
	menu_col_offset = 3,
	native_types = { "/", "?" },
	title = {
		enabled = true,
		pos = "center",
		formats = {
			{ type = ":", pattern = { "^%s*lua%s+", "^%s*lua%s*=", "^%s*=" }, title = " Lua " },
			{ type = ":", pattern = "^%s*!", title = " Shell " },
			{ type = ":", pattern = "^%s*he?l?p?%s+", title = " Help " },
			{ type = "/", title = " Search " },
			{ type = "?", title = " Search " },
			{ type = "=", title = " Expression " },
			{ type = "@", title = " Input " },
			{ type = ">", title = " Debug " },
			{ title = " CmdLine " },
		},
	},
	on_reposition = require("tiny-cmdline").adapters.blink,
}

vim.api.nvim_set_hl(0, "TinyCmdlineNormal", { link = "Normal" })
vim.api.nvim_set_hl(0, "TinyCmdlineBorder", { link = "FloatBorder" })
vim.api.nvim_set_hl(0, "TinyCmdlineTitle", { fg = c.blue, bold = true })
