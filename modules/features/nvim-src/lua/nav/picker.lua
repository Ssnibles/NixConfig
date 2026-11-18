-- fzf-lua: the picker UI, and vim.ui.select routed through it.

local fzf = require("fzf-lua")
local util = require("util")

fzf.setup({
	winopts = {
		height = 0.90,
		width = 0.90,
		row = 0.50,
		col = 0.50,
		border = "rounded",
		backdrop = 100,
		preview = {
			layout = "flex",
			flip_columns = 100,
			vertical = "down:50%",
			horizontal = "right:45%",
			border = "rounded",
			title = false,
		},
	},
	-- Search line at the bottom, matching the navi picker.
	fzf_opts = { ["--layout"] = "default" },
	helptags = { previewer = false },
	keymaps = { previewer = false },
	hl = {
		normal = "FzfLuaNormal",
		border = "FzfLuaBorder",
		preview_normal = "FzfLuaPreviewNormal",
		preview_border = "FzfLuaPreviewBorder",
		help_normal = "FzfLuaNormal",
		help_border = "FzfLuaBorder",
		cursor = "FzfLuaCursor",
		cursorline = "CursorLine",
	},
	previewers = {
		builtin = {
			render_markdown = false,
			treesitter = { enabled = true, disabled = { "markdown", "markdown_inline" }, context = false },
		},
	},
	oldfiles = {
		include_current_session = false,
		cwd_only = true,
		-- Stat entries so missing files and non-files are dropped.
		stat_file = true,
	},
	buffers = {
		filter = function(bufnr)
			if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].buflisted then
				return false
			end
			local buftype, filetype = vim.bo[bufnr].buftype, vim.bo[bufnr].filetype
			-- The picker is itself a terminal buffer of filetype "fzf" and can
			-- outlive a hidden picker, so never offer it as a buffer.
			if util.is_helper_ft(filetype) then
				return false
			end
			if buftype == "terminal" then
				return true
			end
			return buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= ""
		end,
	},
	grep = { rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'" },
	keymap = { fzf = { ["ctrl-q"] = "select-all+accept", ["ctrl-/"] = "toggle-preview" } },
})

fzf.register_ui_select()

-- :checkhealth records a "health://" entry in shada oldfiles and Neovim
-- keeps re-reading it. Shada is read after init, so filter on VimEnter, once
-- the list has been filled. This cleans :oldfiles and every picker.
vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("UserOldfiles", { clear = true }),
	once = true,
	callback = function()
		local files = {}
		for _, file in ipairs(vim.v.oldfiles) do
			if not file:match("^%a[%w+.-]*://") then
				files[#files + 1] = file
			end
		end
		vim.v.oldfiles = files
	end,
})
