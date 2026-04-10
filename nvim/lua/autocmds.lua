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

-- Close utility buffers with q
autocmd("FileType", {
	group = augroup,
	pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "fyler", "noice", "grug-far" },
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
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
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
	end,
})

-- Keep terminal buffers ergonomically isolated
autocmd("TermOpen", {
	group = augroup,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})

-- Start terminals in insert mode for immediate shell interaction
autocmd("BufEnter", {
	group = augroup,
	pattern = "term://*",
	command = "startinsert",
})
