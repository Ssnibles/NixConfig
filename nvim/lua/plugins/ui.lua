-- UI components: statusline, indentation, scrolling, notifications

-- Lualine: statusline
local lualine_theme = {
	normal = {
		a = { fg = "#6e94b2", bg = "#141415", gui = "bold" },
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	insert = { a = { fg = "#7fa563", bg = "#141415", gui = "bold" } },
	visual = { a = { fg = "#bb9dbd", bg = "#141415", gui = "bold" } },
	inactive = { a = { fg = "#252530", bg = "#141415" } },
}

require("lualine").setup({
	options = {
		theme = lualine_theme,
		component_separators = "",
		section_separators = "",
		globalstatus = true,
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { { "filename", path = 1 } },
		lualine_x = { "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})

-- Indent-blankline: indent guides
require("ibl").setup({
	indent = { char = "│" },
	scope = { enabled = true, show_start = false, show_end = false },
	exclude = { filetypes = { "help", "dashboard", "lazy", "mason", "notify", "fyler" } },
})

-- Statuscol: custom status column
local builtin = require("statuscol.builtin")
require("statuscol").setup({
	relculright = true,
	segments = {
		{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
		{ text = { "%s" }, click = "v:lua.ScSa" },
		{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
	},
})

-- Neoscroll: smooth scrolling
require("neoscroll").setup({ easing = "quadratic", hide_cursor = true })

-- Noice: enhanced UI
require("noice").setup({
	cmdline = {
		view = "cmdline",
		format = {
			cmdline = { icon = "", view = "cmdline" },
			search_down = { icon = " " },
			search_up = { icon = " " },
			filter = { icon = "$" },
			lua = { icon = "", view = "cmdline" },
			help = { icon = "", view = "cmdline" },
			input = { icon = "󰥻 " },
		},
	},
	popupmenu = {
		enabled = true,
		backend = "nui",
	},
	lsp = {
		progress = { enabled = false },
		signature = { enabled = false },
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
	},
	presets = { bottom_search = true, inc_rename = true },
	notify = { enabled = false },
})

-- Tiny inline diagnostics
require("tiny-inline-diagnostic").setup({
	preset = "modern",
	options = {
		show_source = { enabled = false, if_many = true },
		multilines = { enabled = true, always_show = true },
		throttle = 20,
		enable_on_insert = false,
	},
})

-- Markview: markdown preview
require("markview").setup({
	modes = { "n", "no" },
	hybrid_modes = { "n", "no" },
})
