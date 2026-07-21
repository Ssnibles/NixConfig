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
	float = { border = "rounded", source = true, max_width = 60 },
	update_in_insert = false,
})

vim.fn.sign_define("DiagnosticSignError", { text = "×", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "▲", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = "•", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "•", texthl = "DiagnosticSignHint" })

require("tiny-inline-diagnostic").setup({
	hi = {
		error = "DiagnosticVirtualTextError",
		warn = "DiagnosticVirtualTextWarn",
		info = "DiagnosticVirtualTextInfo",
		hint = "DiagnosticVirtualTextHint",
		arrow = "NonText",
		background = "CursorLine",
		mixing_color = "Normal",
	},
	blend = { factor = 0.10 },
	signs = {
		left = "", right = "", diag = "●",
		arrow = " ", up_arrow = " ",
		vertical = " │", vertical_end = " └",
	},
	options = {
		use_icons_from_diagnostic = true,
		show_source = { enabled = false },
		show_code = false,
		format = function(diagnostic)
			local msg = diagnostic.message
			return msg and msg:gsub("%s+", " "):gsub("\n", " ") or ""
		end,
		throttle = 20,
		softwrap = 30,
		multilines = { enabled = true, always_show = true },
	},
})
