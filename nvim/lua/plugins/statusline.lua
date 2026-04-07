-- =============================================================================
-- Statusline and UI Chrome (Vague Style)
-- =============================================================================
local loader = require("lib.loader")

local theme = {
	normal = {
		a = { fg = "#6e94b2", bg = "#141415", gui = "bold" },
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	insert = { a = { fg = "#7fa563", bg = "#141415", gui = "bold" } },
	visual = { a = { fg = "#bb9dbd", bg = "#141415", gui = "bold" } },
	inactive = { a = { fg = "#252530", bg = "#141415" } },
}

loader.setup("lualine", {
	options = { theme = theme, component_separators = "", section_separators = "", globalstatus = true },
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { { "filename", path = 1 } },
		lualine_x = { "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})

loader.setup("ibl", {
	indent = { char = "│" },
	scope = { enabled = true, show_start = false, show_end = false },
})

loader.setup("statuscol", function(statuscol)
	local builtin = require("statuscol.builtin")
	statuscol.setup({
		relculright = true,
		segments = {
			{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
			{ text = { "%s" }, click = "v:lua.ScSa" },
			{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
		},
	})
end)

loader.setup("neoscroll", { easing = "quadratic", hide_cursor = true })
