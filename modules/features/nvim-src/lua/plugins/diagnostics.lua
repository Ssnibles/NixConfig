-- Diagnostics configuration, inline diagnostic virtual text, and Fidget progress/notifications

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

local ok_tid, tid = pcall(require, "tiny-inline-diagnostic")
if ok_tid then
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
			overflow = {
				mode = "wrap",
			},
			break_line = {
				enabled = true,
				after = 40,
			},
			virt_texts = {
				priority = 2048,
			},
		},
	})
end

local ok_fidget, fidget = pcall(require, "fidget")
if ok_fidget then
	fidget.setup({ notification = { override_vim_notify = true } })
end
