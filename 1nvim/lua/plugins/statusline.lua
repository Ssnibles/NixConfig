-- =============================================================================
-- Statusline and UI Chrome Configuration
-- =============================================================================
-- lualine (statusline), ibl (indent guides), neoscroll (smooth scrolling),
-- statuscol (fold/sign/line column).

-- ── lualine Theme ──────────────────────────────────────────────────────────
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

-- ── mini.diff Status ───────────────────────────────────────────────────────
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

-- ── lualine Setup ──────────────────────────────────────────────────────────
local lualine_ok = pcall(require, "lualine")
if lualine_ok then
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
end

-- ── indent-blankline Configuration ─────────────────────────────────────────
local ibl_ok = pcall(require, "ibl")
if ibl_ok then
	require("ibl").setup({
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
end

-- ── neoscroll Configuration ────────────────────────────────────────────────
local neoscroll_ok = pcall(require, "neoscroll")
if neoscroll_ok then
	require("neoscroll").setup({
		mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
		easing = "quadratic",
		hide_cursor = true,
		respect_scrolloff = true,
	})
end

-- ── statuscol Configuration ────────────────────────────────────────────────
local statuscol_ok = pcall(require, "statuscol")
if statuscol_ok then
	local builtin = require("statuscol.builtin")
	require("statuscol").setup({
		relculright = true,
		segments = {
			{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
			{ text = { "%s" }, click = "v:lua.ScSa" },
			{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
		},
		ft_ignore = { "neo-tree", "oil" },
	})
end
