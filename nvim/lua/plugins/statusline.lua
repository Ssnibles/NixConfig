-- =============================================================================
-- Statusline and UI Chrome Configuration
-- =============================================================================
-- lualine (statusline), ibl (indent guides), neoscroll (smooth scrolling),
-- statuscol (fold/sign/line column). All visual chrome in one place.
--
-- Diff summary: mini_diff_status removed. The lualine "diff" component is
-- pointed at gitsigns as its sole source — no duplication with mini.diff.
-- =============================================================================

local loader = require("lib.loader")

-- ── lualine Theme ─────────────────────────────────────────────────────────
-- All sections share the same background (#141415) so the statusline reads
-- as a single flat bar. Only the mode indicator changes colour.
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

-- ── lualine Setup ─────────────────────────────────────────────────────────
loader.setup("lualine", function(lualine)
	lualine.setup({
		options = {
			theme = theme,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			globalstatus = true,
			disabled_filetypes = { statusline = { "dashboard", "alpha" } },
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = {
				{ "branch", icon = "", color = { fg = "#878787" } },
				{
					-- Explicitly use gitsigns as the diff source so lualine
					-- never tries to fall back to mini.diff (which is removed)
					"diff",
					source = function()
						local gs = package.loaded["gitsigns"]
						if gs then
							local status = gs.status_dict
							if status then
								return {
									added = status.added,
									modified = status.changed,
									removed = status.removed,
								}
							end
						end
					end,
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
			lualine_x = {
				{ "filetype", color = { fg = "#878787" } },
			},
			lualine_y = { { "progress", color = { fg = "#606079" } } },
			lualine_z = { { "location", color = { fg = "#606079" } } },
		},
		inactive_sections = {
			lualine_c = { { "filename", path = 1, color = { fg = "#252530", gui = "italic" } } },
			lualine_x = { { "location", color = { fg = "#252530" } } },
		},
	})
end)

-- ── indent-blankline ──────────────────────────────────────────────────────
loader.setup("ibl", function(ibl)
	ibl.setup({
		enabled = true,
		indent = {
			char = "│",
			highlight = "IblIndent",
			smart_indent_cap = true,
		},
		scope = {
			enabled = true,
			highlight = "IblScope",
			show_start = true,
			show_end = true,
			show_exact_scope = true,
		},
		exclude = {
			filetypes = { "help", "dashboard", "oil", "neo-tree" },
		},
	})
end)

-- ── neoscroll ─────────────────────────────────────────────────────────────
loader.setup("neoscroll", function(neoscroll)
	neoscroll.setup({
		mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
		easing = "quadratic",
		hide_cursor = true,
		respect_scrolloff = true,
	})
end)

-- ── statuscol ─────────────────────────────────────────────────────────────
loader.setup("statuscol", function(statuscol)
	local builtin = require("statuscol.builtin")
	statuscol.setup({
		relculright = true,
		segments = {
			-- Fold indicator only shown when there are actual folds to interact
			-- with; statuscol renders it dynamically so this is fine at init
			{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
			{ text = { "%s" }, click = "v:lua.ScSa" },
			{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
		},
		ft_ignore = { "neo-tree", "oil" },
	})
end)
