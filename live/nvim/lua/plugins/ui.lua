-- UI components: statusline, indentation, scrolling, notifications

local c = require("theme").colors

-- Lualine: statusline
local lualine_theme = {
	normal = {
		a = { fg = c.blue, bg = c.bg, gui = "bold" },
		b = { fg = c.fg, bg = c.bg },
		c = { fg = c.comment, bg = c.bg },
	},
	insert = { a = { fg = c.green, bg = c.bg, gui = "bold" } },
	visual = { a = { fg = c.purple, bg = c.bg, gui = "bold" } },
	inactive = { a = { fg = c.gutter, bg = c.bg } },
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
		lualine_x = { "filetype", "encoding", "fileformat" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
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
		enabled = false,
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
	routes = {
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "%d+L, %d+B" },
					{ find = "; after #%d+" },
					{ find = "; before #%d+" },
					{ find = "Written" },
				},
			},
			view = "mini",
		},
		{
			filter = {
				event = "msg_show",
				kind = "search_count",
			},
			opts = { skip = true },
		},
	},
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
local markview_filetypes = { "markdown", "quarto", "rmd", "typst" }
local markview_filetype_set = {}
for _, ft in ipairs(markview_filetypes) do
	markview_filetype_set[ft] = true
end

vim.g.__markview_startup_ready = false
require("markview").setup({
	preview = {
		filetypes = markview_filetypes,
		-- Gate auto-attach until startup settles; manual :Markview commands still work.
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
				if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and markview_filetype_set[vim.bo[buf].filetype] then
					actions.attach(buf)
				end
			end
		end, 150)
	end,
})
