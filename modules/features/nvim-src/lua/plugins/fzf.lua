local fzf = require("fzf-lua")

-- Excluded filetypes for buffer pickers
local excluded_ft = {
	oil = true,
	fugitive = true,
	qf = true,
	help = true,
	fzf = true,
	ministarter = true,
	Trouble = true,
}

fzf.setup({
	winopts = {
		height = 0.85, width = 0.85, row = 0.50, col = 0.50,
		border = "rounded", backdrop = 100,
		preview = {
			layout = "flex", flip_columns = 100,
			vertical = "down:50%", horizontal = "right:50%",
			border = "rounded", title = false,
		},
	},
	helptags = { previewer = false },
	keymaps = { previewer = false },
	hl = {
		normal = "FzfLuaNormal", border = "FzfLuaBorder",
		preview_normal = "FzfLuaPreviewNormal", preview_border = "FzfLuaPreviewBorder",
		help_normal = "FzfLuaNormal", help_border = "FzfLuaBorder",
		cursor = "FzfLuaCursor", cursorline = "CursorLine",
	},
	previewers = {
		builtin = {
			render_markdown = false,
			treesitter = { enabled = true, disabled = { "markdown", "markdown_inline" }, context = false },
		},
	},
	oldfiles = { include_current_session = false, cwd_only = true, stat_file = false },
	buffers = {
		filter = function(bufnr)
			if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].buflisted then
				return false
			end
			local bt = vim.bo[bufnr].buftype
			local ft = vim.bo[bufnr].filetype
			local name = vim.api.nvim_buf_get_name(bufnr)

			if bt == "terminal" or ft == "terminal" or name:match("^term://") then
				return true
			end
			if bt ~= "" or name == "" then
				return false
			end
			if excluded_ft[ft] or ft:find("^grug%-far") then
				return false
			end
			return true
		end,
	},
	grep = { rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'" },
	keymap = { fzf = { ["ctrl-q"] = "select-all+accept", ["ctrl-/"] = "toggle-preview" } },
})
