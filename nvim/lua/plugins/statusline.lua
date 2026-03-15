-- Statusline and UI chrome:
--   lualine   — statusline
--   ibl       — indent guides
--   neoscroll — smooth scrolling
--   statuscol — custom status column (folds + signs + line numbers)
--   fidget    — LSP progress spinner

-- ── lualine ───────────────────────────────────────────────────────────────
-- All sections share the same #141415 background — one flat surface,
-- matching the Waybar aesthetic. Mode colour maps to vague semantic roles.

local theme = {
	normal = {
		a = { fg = "#6e94b2", bg = "#141415", gui = "bold" },
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	insert = {
		a = { fg = "#7fa563", bg = "#141415", gui = "bold" },
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	visual = {
		a = { fg = "#bb9dbd", bg = "#141415", gui = "bold" },
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	replace = {
		a = { fg = "#d8647e", bg = "#141415", gui = "bold" },
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	command = {
		a = { fg = "#f3be7c", bg = "#141415", gui = "bold" },
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	inactive = {
		a = { fg = "#252530", bg = "#141415" },
		b = { fg = "#252530", bg = "#141415" },
		c = { fg = "#252530", bg = "#141415" },
	},
}

require("lualine").setup({
	options = {
		theme = theme,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		globalstatus = true,
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = {
			{ "branch", icon = "", color = { fg = "#878787" } },
			{
				"diff",
				symbols = { added = " ", modified = " ", removed = " " },
				diff_color = {
					added = { fg = "#7fa563" },
					modified = { fg = "#f3be7c" },
					removed = { fg = "#d8647e" },
				},
			},
			{
				"diagnostics",
				symbols = { error = "󰅚 ", warn = "󰀪 ", hint = "󰌶 ", info = "󰋽 " },
				diagnostics_color = {
					error = { fg = "#d8647e" },
					warn = { fg = "#f3be7c" },
					hint = { fg = "#b4d4cf" },
					info = { fg = "#6e94b2" },
				},
			},
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				color = { fg = "#606079", gui = "italic" },
				symbols = { modified = " ●", readonly = " 󰌾", unnamed = "[no name]" },
			},
		},
		lualine_x = { { "filetype", color = { fg = "#878787" } } },
		lualine_y = { { "progress", color = { fg = "#606079" } } },
		lualine_z = { { "location", color = { fg = "#606079" } } },
	},
	inactive_sections = {
		lualine_c = { { "filename", path = 1, color = { fg = "#252530", gui = "italic" } } },
		lualine_x = { { "location", color = { fg = "#252530" } } },
	},
})

-- ── indent-blankline ──────────────────────────────────────────────────────
require("ibl").setup({
	indent = { char = "│", highlight = "IblIndent" },
	scope = {
		enabled = true,
		show_start = true,
		show_end = false,
		highlight = "IblScope",
	},
	exclude = {
		filetypes = { "help", "dashboard", "lazy", "mason", "oil", "which-key" },
	},
})

-- ── neoscroll ─────────────────────────────────────────────────────────────
require("neoscroll").setup({
	mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
	easing = "quadratic",
	hide_cursor = true,
	respect_scrolloff = true,
})

-- ── statuscol ─────────────────────────────────────────────────────────────
local builtin = require("statuscol.builtin")
require("statuscol").setup({
	relculright = true,
	segments = {
		{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
		{ text = { "%s" }, click = "v:lua.ScSa" },
		{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
	},
	ft_ignore = { "neo-tree", "lazy", "mason" },
})

-- ── fidget ────────────────────────────────────────────────────────────────
require("fidget").setup({
	notification = { window = { winblend = 0, border = "none" } },
})
