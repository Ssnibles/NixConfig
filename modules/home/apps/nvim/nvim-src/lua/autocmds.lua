-- Autocommands
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Flash yanked region
autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank({ timeout = 200 })
	end,
})

-- Check if files changed outside Neovim and keep them in sync
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup,
	command = "checktime",
})

-- Restore cursor position
autocmd("BufReadPost", {
	group = augroup,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Trim trailing whitespace on save (via mini.trailspace if available)
autocmd("BufWritePre", {
	group = augroup,
	callback = function()
		if vim.bo.buftype ~= "" then
			return
		end
		local skip = { markdown = true, text = true, gitcommit = true, diff = true }
		if skip[vim.bo.filetype] then
			return
		end
		local ok, ts = pcall(require, "mini.trailspace")
		if ok then
			ts.trim()
			ts.trim_last_lines()
		end
	end,
})

-- Close utility buffers with q or Esc
autocmd("FileType", {
	group = augroup,
	pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "oil", "noice", "grug-far" },
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
		vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
	end,
})

-- Auto-resize splits
autocmd("VimResized", {
	group = augroup,
	command = "wincmd =",
})

-- Disable auto-comment continuation
autocmd("FileType", {
	group = augroup,
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Prose settings for text files
autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "markdown.mdx", "text", "gitcommit" },
	callback = function(ev)
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
		vim.wo.colorcolumn = "80"
		if (vim.version().major == 0 and vim.version().minor >= 12) then
			if vim.bo[ev.buf].filetype == "markdown" or vim.bo[ev.buf].filetype == "markdown.mdx" then
				-- Avoid intermittent Neovim 0.12 treesitter node-range crashes in markdown buffers.
				pcall(vim.treesitter.stop, ev.buf)
			end
		end
	end,
})

if vim.version().major == 0 and vim.version().minor >= 12 then
	autocmd("BufEnter", {
		group = augroup,
		callback = function(ev)
			local ft = vim.bo[ev.buf].filetype
			if ft ~= "markdown" and ft ~= "markdown.mdx" then
				return
			end
			-- Some plugins start treesitter on BufEnter; stop it again after callbacks settle.
			pcall(vim.treesitter.stop, ev.buf)
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(ev.buf) then
					return
				end
				local scheduled_ft = vim.bo[ev.buf].filetype
				if scheduled_ft == "markdown" or scheduled_ft == "markdown.mdx" then
					pcall(vim.treesitter.stop, ev.buf)
				end
			end)
		end,
	})
end

autocmd("TermOpen", {
	group = augroup,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.wo.cursorline = false
	end,
})

-- Start terminals in insert mode for immediate shell interaction
autocmd("BufEnter", {
	group = augroup,
	pattern = "term://*",
	command = "startinsert",
})

-- Switch to absolute line numbers in insert mode, back to relative on leave
autocmd("InsertEnter", {
	group = augroup,
	callback = function()
		local ok, _ = pcall(function()
			return vim.wo.relativenumber
		end)
		if ok and vim.wo.relativenumber then
			vim.wo.relativenumber = false
			vim.wo.number = true
		end
	end,
})
autocmd("InsertLeave", {
	group = augroup,
	callback = function()
		vim.wo.number = true
		vim.wo.relativenumber = true
	end,
})

-- Show cursorline only in active window to reduce visual noise
autocmd("WinEnter", {
	group = augroup,
	callback = function()
		vim.wo.cursorline = true
	end,
})
autocmd("WinLeave", {
	group = augroup,
	callback = function()
		vim.wo.cursorline = false
	end,
})

-- Per-filetype fold overrides: disable treesitter-folds for prose, use indent for configs
autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "markdown.mdx", "text", "gitcommit", "typst", "txt" },
	callback = function()
		vim.wo.foldmethod = "indent"
		vim.wo.foldenable = false
	end,
})

autocmd("FileType", {
	group = augroup,
	pattern = { "yaml", "json", "toml" },
	callback = function()
		vim.wo.foldmethod = "indent"
	end,
})

-- Keywordprg: use `:help` for lua/vim, `:Man` fallback everywhere else
autocmd("FileType", {
	group = augroup,
	pattern = { "lua", "vim" },
	callback = function()
		vim.bo.keywordprg = ":help"
	end,
})

autocmd("FileType", {
	group = augroup,
	pattern = "typst",
	callback = function()
		vim.keymap.set("n", "<leader>tp", function()
			vim.cmd("TypstPreviewToggle")
		end, { buffer = true, desc = "Toggle Typst preview" })
	end,
})

-- Large files: disable certain features to keep things fast
autocmd({ "BufReadPre", "BufNewFile" }, {
	group = augroup,
	callback = function()
		local path = vim.fn.expand("<afile>:p")
		if vim.bo.buftype ~= "" or not vim.bo.modifiable then
			return
		end
		local ok, stat = pcall(vim.uv.fs_stat, path)
		if not ok or not stat then
			return
		end
		local size_mb = stat.size / (1024 * 1024)
		if size_mb > 5 then
			vim.b.large_file = true
			vim.wo.foldmethod = "manual"
			vim.wo.foldenable = false
			vim.bo.syntax = ""
		end
	end,
})
