-- Statusline and UI chrome:
--   lualine   — statusline
--   ibl       — indent guides + scope highlighting
--   neoscroll — smooth scrolling
--   statuscol — custom status column (folds + signs + line numbers)
--   fidget    — LSP progress spinner

-- ── lualine ───────────────────────────────────────────────────────────────
-- Flat single-surface theme; mode colour maps to vague semantic palette.

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

-- Mini diff hunk counts for the statusline
local function mini_diff_status()
	local ok, data = pcall(require("mini.diff").get_buf_data)
	if not ok or not data or not data.summary then
		return ""
	end
	local s = data.summary
	local parts = {}
	if (s.add or 0) > 0 then
		parts[#parts + 1] = "+" .. s.add
	end
	if (s.change or 0) > 0 then
		parts[#parts + 1] = "~" .. s.change
	end
	if (s.delete or 0) > 0 then
		parts[#parts + 1] = "-" .. s.delete
	end
	return #parts > 0 and table.concat(parts, " ") or ""
end

require("lualine").setup({
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
		lualine_x = {
			{ mini_diff_status, color = { fg = "#606079" } },
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

-- ── indent-blankline ──────────────────────────────────────────────────────
-- ibl handles both the static indent guide lines and the active scope line.
--
-- Scope detection: ibl v3 attaches its own treesitter LanguageTree listener
-- per buffer. It works correctly only when treesitter's indent module is OFF
-- (see treesitter.lua — indent = { enable = false }). With that in place ibl
-- reliably highlights the indent guide column of the innermost scope, and
-- draws an underline on the scope's opening and closing lines.
--
-- ^I fix: with 'list' on but no 'tab' entry in listchars, Neovim renders raw
-- tab characters as ^I. Adding tab = "  " tells Neovim to render tabs as two
-- spaces in list mode, which eliminates the ^I bleed-through on tab-indented
-- files (e.g. Go, Makefiles).
vim.opt.listchars:append({ tab = "  " })

-- IblIndent  — dim guide lines (all indent levels)
-- IblScope   — the active scope's guide line (brighter)
-- IblScopeUnderline — underline sp colour on the scope open/close lines
vim.api.nvim_set_hl(0, "IblIndent", { fg = "#252530" })
vim.api.nvim_set_hl(0, "IblScope", { fg = "#4a4a6a" })
vim.api.nvim_set_hl(0, "IblScopeUnderline", { sp = "#4a4a6a", underline = true })

require("ibl").setup({
	indent = {
		char = "│",
		highlight = "IblIndent",
	},
	scope = {
		enabled = true,
		highlight = "IblScope",
		-- show_start / show_end draw an underline on the opening and closing
		-- lines of the current scope, making the block boundary visible.
		show_start = true,
		show_end = true,
		-- Use the dedicated underline group so the boundary lines don't need
		-- to change the guide colour — only the sp (underline colour) matters.
		show_exact_scope = false,
	},
	exclude = {
		filetypes = { "help", "dashboard", "alpha", "lazy", "mason", "oil" },
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
	ft_ignore = { "neo-tree", "lazy", "mason", "oil" },
})

-- ── fidget ────────────────────────────────────────────────────────────────
require("fidget").setup({
	notification = { window = { winblend = 0, border = "none" } },
})
