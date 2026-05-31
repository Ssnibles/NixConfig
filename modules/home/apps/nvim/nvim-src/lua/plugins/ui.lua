-- UI: lualine, snacks, noice, statuscol, markview, diagnostics.
-- All surfaces share the editor background for a flat, modern appearance.

local c = require("theme").colors
local t = require("theme")

-- ═══════════════════════════════════════════════════════════════════
--  S N A C K S . N V I M   (terminal)
-- ═══════════════════════════════════════════════════════════════════

require("snacks").setup({
	terminal = {
		enabled = true,
		win = { style = "terminal" },
	},
})

-- ═══════════════════════════════════════════════════════════════════
--  L U A L I N E
-- ═══════════════════════════════════════════════════════════════════

require("lualine").setup({
	options = {
		theme = t.lualine,
		component_separators = "",
		section_separators = { left = "", right = "" },
		globalstatus = true,
		disabled_filetypes = { statusline = { "dashboard", "snacks_terminal" } },
	},
	sections = {
		lualine_a = {
			{
				"mode",
				fmt = function(str)
					return " " .. str:sub(1, 1) .. " "
				end,
			},
		},
		lualine_b = {
			{
				"branch",
				icon = { " ", align = "left" },
				color = { fg = c.comment },
			},
			{
				"diff",
				colored = true,
				symbols = { added = "+", modified = "~", removed = "-" },
				diff_color = {
					added = { fg = c.green },
					modified = { fg = c.yellow },
					removed = { fg = c.red },
				},
			},
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = "×", warn = "▲", info = "•", hint = "•" },
				padding = { left = 1, right = 0 },
			},
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				symbols = { modified = " ", readonly = " ", new = " ", unnamed = "[No Name]" },
			},
		},
		lualine_x = {
			{
				function()
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					if #clients == 0 then
						return ""
					end
					local names = {}
					for _, client in ipairs(clients) do
						names[#names + 1] = client.name
					end
					return table.concat(names, ", ")
				end,
				icon = { "  ", align = "left" },
				color = { fg = c.comment },
				cond = function()
					return #vim.lsp.get_clients({ bufnr = 0 }) > 0 and vim.bo.filetype ~= ""
				end,
			},
		},
		lualine_y = {
			{
				"filetype",
				colored = false,
				padding = { left = 1, right = 1 },
			},
		},
		lualine_z = {
			{
				function()
					return vim.fn.line(".") .. "/" .. vim.fn.line("$")
				end,
				padding = { left = 1, right = 1 },
			},
		},
	},
	extensions = {},
})

-- ═══════════════════════════════════════════════════════════════════
--  S T A T U S C O L
-- ═══════════════════════════════════════════════════════════════════

local builtin = require("statuscol.builtin")
require("statuscol").setup({
	relculright = true,
	segments = {
		{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
		{ text = { "%s" }, click = "v:lua.ScSa" },
		{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
	},
})

-- ═══════════════════════════════════════════════════════════════════
--  N O I C E   --  fixed-width top-centred command palette
-- ═══════════════════════════════════════════════════════════════════

require("noice").setup({
	cmdline = {
		view = "cmdline_popup",
		format = {
			cmdline = { icon = " ", lang = "vim" },
			search_down = { icon = "  " },
			search_up = { icon = "  " },
			filter = { icon = " " },
			lua = { icon = " " },
			help = { icon = " " },
			input = { icon = " " },
		},
	},
	popupmenu = { enabled = false },
	lsp = {
		progress = { enabled = false },
		signature = { enabled = false },
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
	},
	presets = { bottom_search = true, inc_rename = true, long_message_to_split = true },
	notify = { enabled = false },
	routes = {
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "%d+L, %d+B" },
					{ find = "; after #%d+" },
					{ find = "; before #%d+" },
					{ find = "Written" },
					{ find = "%d+ lines written" },
					{ find = "%d+ files changed" },
					{ find = "Copilot" },
				},
			},
			view = "mini",
		},
		{
			filter = { event = "msg_show", kind = "search_count" },
			opts = { skip = true },
		},
		{
			filter = { event = "msg_show", find = "%%%-%-$" },
			opts = { skip = true },
		},
	},
	views = {
		cmdline_popup = {
			position = { row = "15%", col = "50%" },
			size = { width = 72, height = "auto" },
			border = { style = "rounded", padding = { 0, 1 } },
			win_options = {
				winblend = 0,
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
		},
		mini = { timeout = 1200, win_options = { winblend = 0 } },
	},
})

-- ═══════════════════════════════════════════════════════════════════
--  M A R K V I E W
-- ═══════════════════════════════════════════════════════════════════

local markview_filetypes = { "markdown", "quarto", "rmd" }
local markview_filetype_set = {}
for _, ft in ipairs(markview_filetypes) do
	markview_filetype_set[ft] = true
end

vim.g.__markview_startup_ready = false
require("markview").setup({
	preview = {
		filetypes = markview_filetypes,
		condition = function()
			return vim.g.__markview_startup_ready == true
		end,
	},
	modes = { "n", "no" },
	hybrid_modes = { "n", "no" },
	latex = {
		enable = true,
		inlines = { enable = true },
		blocks = { enable = true },
		symbols = { enable = true },
		commands = { enable = true },
		fonts = { enable = true },
		subscripts = { enable = true },
		superscripts = { enable = true },
	},
})

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.defer_fn(function()
			vim.g.__markview_startup_ready = true
			local actions = require("markview.actions")
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if
					vim.api.nvim_buf_is_valid(buf)
					and vim.bo[buf].buftype == ""
					and markview_filetype_set[vim.bo[buf].filetype]
				then
					actions.attach(buf)
				end
			end
		end, 150)
	end,
})
