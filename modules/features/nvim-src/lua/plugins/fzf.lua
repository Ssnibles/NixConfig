local fzf = require("fzf-lua")

-- Shared ignore patterns for files and buffers
local ignore_patterns = {
	"^oil$", "^oil://", "oil://", "^grug%-far", "grug%-far",
	"^fugitive$", "^fugitive://", "fugitive://",
	"^term$", "^term://", "term://",
	"^NvimTree_", "^neo%-tree", "^Trouble",
	"^%[.*%]$", "^[^/%%.]+$", "/[^/%%.]+$",
}

local function is_valid_file_extension(name)
	if not name or name == "" or name:match("^%w+://") or name:match("^%[.*%]$") then return false end
	local tail = vim.fn.fnamemodify(name, ":t")
	if not tail or tail == "" then return false end
	if tail:match("%.([a-zA-Z0-9_-]+)$") then return true end
	local valid = { Makefile = true, Dockerfile = true, Containerfile = true, LICENSE = true, LICENCE = true, Justfile = true, Rakefile = true }
	return valid[tail] == true
end

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
	file_ignore_patterns = ignore_patterns,
	oldfiles = { include_current_session = false, cwd_only = true, stat_file = false },
	buffers = {
		file_ignore_patterns = ignore_patterns,
		filter = function(bufnr)
			local bt = vim.bo[bufnr].buftype
			local ft = vim.bo[bufnr].filetype
			local name = vim.api.nvim_buf_get_name(bufnr)

			if bt == "terminal" or name:match("^term://") or ft == "terminal" then return true end
			if bt ~= "" then return false end
			if ft == "oil" or ft:find("^grug%-far") or ft == "fugitive" or ft == "qf" or ft == "help" or ft == "fzf" then
				return false
			end
			return is_valid_file_extension(name)
		end,
	},
	grep = { rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'" },
	keymap = { fzf = { ["ctrl-q"] = "select-all+accept", ["ctrl-/"] = "toggle-preview" } },
})
