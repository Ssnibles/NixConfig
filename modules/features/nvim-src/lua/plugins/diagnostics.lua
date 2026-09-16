local ok, tid = pcall(require, "tiny-inline-diagnostic")
if not ok then
	return
end

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
