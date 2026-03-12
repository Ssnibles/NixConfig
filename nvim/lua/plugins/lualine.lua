-- ============================================================================
-- LUALINE (statusline)
-- Styled to match the Waybar aesthetic:
--   • flat bg (#141415), no section fills
--   • thin 1px border colour (#252530) used as separators between sections
--   • no powerline arrows — plain empty separators keep it borderless
--   • dimmed text (#606079) for secondary info, fg (#cdcdcd) for primary
--   • mode accent colours follow the same vague semantic roles used in Waybar
--
-- Mode → accent mapping (mirrors Waybar's active/urgent/state colours):
--   normal  → keyword   #6e94b2  (blue — Waybar active workspace)
--   insert  → plus      #7fa563  (green — Waybar battery charging)
--   visual  → parameter #bb9dbd  (purple — Waybar mpris)
--   replace → error     #d8647e  (red — Waybar battery critical)
--   command → warning   #f3be7c  (amber — Waybar battery warning)
-- ============================================================================

-- ============================================================================
-- THEME
-- All sections share the same #141415 background so the bar looks like a
-- single flat surface — exactly how the Waybar window sits on screen.
-- The mode pill uses a subtle fg tint rather than a filled block so it
-- doesn't feel heavier than the rest of the bar.
-- ============================================================================
local vague_lualine = {
	normal = {
		a = { fg = "#6e94b2", bg = "#141415", gui = "bold" }, -- keyword blue
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" }, -- comment / dimmed
	},
	insert = {
		a = { fg = "#7fa563", bg = "#141415", gui = "bold" }, -- plus green
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	visual = {
		a = { fg = "#bb9dbd", bg = "#141415", gui = "bold" }, -- parameter purple
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	replace = {
		a = { fg = "#d8647e", bg = "#141415", gui = "bold" }, -- error red
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	command = {
		a = { fg = "#f3be7c", bg = "#141415", gui = "bold" }, -- warning amber
		b = { fg = "#cdcdcd", bg = "#141415" },
		c = { fg = "#606079", bg = "#141415" },
	},
	inactive = {
		a = { fg = "#252530", bg = "#141415" }, -- line colour — barely visible
		b = { fg = "#252530", bg = "#141415" },
		c = { fg = "#252530", bg = "#141415" },
	},
}

require("lualine").setup({
	options = {
		theme = vague_lualine,
		-- Empty separators = no arrows, no fills — matches the flat Waybar style.
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		-- Single bar across all splits, same as Waybar spans the full display.
		globalstatus = true,
	},
	sections = {
		-- Mode: coloured text only, no pill background.
		lualine_a = { "mode" },

		-- Left group: branch + diff + diagnostics, separated from mode by the
		-- thin #252530 line colour — mirrors Waybar's border-right dividers.
		lualine_b = {
			{ "branch", icon = "", color = { fg = "#878787" } }, -- floatBorder mid-tone
			{
				"diff",
				symbols = { added = " ", modified = " ", removed = " " },
				diff_color = {
					added = { fg = "#7fa563" }, -- plus
					modified = { fg = "#f3be7c" }, -- warning
					removed = { fg = "#d8647e" }, -- error
				},
			},
			{
				"diagnostics",
				symbols = { error = "󰅚 ", warn = "󰀪 ", hint = "󰌶 ", info = "󰋽 " },
				diagnostics_color = {
					error = { fg = "#d8647e" },
					warn = { fg = "#f3be7c" },
					hint = { fg = "#b4d4cf" }, -- builtin teal
					info = { fg = "#6e94b2" }, -- keyword blue
				},
			},
		},

		-- Centre: relative file path in dimmed text, italic like the Waybar
		-- window-title module.
		lualine_c = {
			{
				"filename",
				path = 1, -- relative path
				color = { fg = "#606079", gui = "italic" }, -- comment / fg-dim
				symbols = { modified = " ●", readonly = " 󰌾", unnamed = "[no name]" },
			},
		},

		-- Right group: filetype in mid-tone, progress + location in fg-dim —
		-- mirrors how Waybar dims secondary status indicators.
		lualine_x = {
			{ "filetype", color = { fg = "#878787" } }, -- floatBorder mid-tone
		},
		lualine_y = {
			{ "progress", color = { fg = "#606079" } }, -- comment / fg-dim
		},
		lualine_z = {
			{ "location", color = { fg = "#606079" } }, -- comment / fg-dim
		},
	},

	-- Inactive splits: everything fades to the line colour (#252530) so
	-- unfocused buffers recede, same as Waybar's inactive workspace buttons.
	inactive_sections = {
		lualine_c = {
			{ "filename", path = 1, color = { fg = "#252530", gui = "italic" } },
		},
		lualine_x = {
			{ "location", color = { fg = "#252530" } },
		},
	},
})
