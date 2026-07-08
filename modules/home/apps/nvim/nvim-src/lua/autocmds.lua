-- Autocommands
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Suppress native :write file-info messages so they don't cover lualine.
-- BufWriteCmd runs instead of the built-in write, letting us use :silent.
-- We manually fire BufWritePre/Post so format-on-save and trailspace trimming keep working.
local writing = false
autocmd("BufWriteCmd", {
	group = augroup,
	pattern = "*",
	callback = function(ev)
		if writing then
			return
		end
		writing = true

		local buf = ev.buf
		local bo = vim.bo[buf]
		local name = vim.api.nvim_buf_get_name(buf)

		-- For special or unnamed buffers, fall back to the built-in behavior.
		if bo.buftype ~= "" or name == "" then
			pcall(vim.cmd, "noautocmd write")
			writing = false
			return
		end

		-- Run BufWritePre hooks (format-on-save, trailspace trim, etc.).
		vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buf, modeline = false })

		-- Actually write the file, silently suppressing the file-info message.
		local ok, err = pcall(vim.cmd, "silent noautocmd write")

		-- Run BufWritePost hooks.
		vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf, modeline = false })

		writing = false

		if not ok then
			vim.notify("Write failed: " .. tostring(err), vim.log.levels.ERROR)
		end
	end,
})

-- Workaround: files opened via fyler's :edit don't always trigger filetype
-- detection. Uses match() which is available in all modern Neovim versions.
vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("FixFiletypeDetection", { clear = true }),
	desc = "Detect filetype if empty (fyler workaround)",
	callback = function(ev)
		if vim.bo[ev.buf].filetype == "" and vim.bo[ev.buf].buftype == "" then
			local name = vim.api.nvim_buf_get_name(ev.buf)
			if name and name ~= "" and vim.fn.filereadable(name) == 1 then
				local ft = vim.filetype.match({ filename = name, buf = ev.buf })
				if ft and ft ~= "" then
					vim.bo[ev.buf].filetype = ft
				end
			end
		end
	end,
})

-- Enable inlay hints automatically for any buffer that gets an LSP client.
-- We call enable unconditionally (wrapped in pcall) because some servers
-- (e.g., jdtls) dynamically register the capability after attach, and
-- setting the buffer state to "enabled" means hints show up as soon as the
-- server advertises support. We only do this once per buffer so a manual
-- toggle off with <leader>ti is respected.
autocmd("LspAttach", {
	group = augroup,
	callback = function(args)
		if vim.b[args.buf]._inlay_hints_auto_enabled then
			return
		end
		pcall(vim.lsp.inlay_hint.enable, true, { bufnr = args.buf })
		vim.b[args.buf]._inlay_hints_auto_enabled = true
	end,
})

-- Flash yanked region
autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank({ timeout = 200 })
	end,
})

-- Check if files changed outside Neovim and keep them in sync
autocmd({ "FocusGained" }, {
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

-- Trim trailing whitespace on save (via mini.trailspace)
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
		local ts = require("mini.trailspace")
		ts.trim()
		ts.trim_last_lines()
	end,
})

-- Close utility buffers with q or Esc
autocmd("FileType", {
	group = augroup,
	pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "oil", "grug-far", "NeogitStatus", "cargo" },
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
		if require("version") then
			if vim.bo[ev.buf].filetype == "markdown" or vim.bo[ev.buf].filetype == "markdown.mdx" then
				pcall(vim.treesitter.stop, ev.buf)
			end
		end
	end,
})

autocmd("TermOpen", {
	group = augroup,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.wo.cursorline = false
	end,
})

-- Ensure signcolumn is visible on real file buffers (safety net for dashboard/Oil transitions)
autocmd("BufWinEnter", {
	group = augroup,
	callback = function()
		local bt = vim.bo.buftype
		if bt == "terminal" or bt == "nofile" or bt == "acwrite" then
			return
		end
		if vim.wo.signcolumn == "no" then
			vim.wo.signcolumn = vim.o.signcolumn
		end
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
		if vim.wo.relativenumber then
			vim.wo.relativenumber = false
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
		if vim.bo.buftype ~= "terminal" then
			vim.wo.cursorline = true
		end
	end,
})
autocmd("WinLeave", {
	group = augroup,
	callback = function()
		if vim.bo.buftype ~= "terminal" then
			vim.wo.cursorline = false
		end
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

-- Completely suppress trailspace for specified utility and UI buffers
local function disable_trailspace(ev)
	local ignore_filetypes = {
		"help",
		"snacks_dashboard",
		"alpha",
		"NvimTree",
		"neo-tree",
		"lazy",
		"mason",
		"trouble",
	}

	local ignore_buftypes = {
		"nofile",
		"quickfix",
		"terminal",
		"prompt",
	}

	local buf = ev and ev.buf or 0
	local ft = vim.bo[buf].filetype
	local bt = vim.bo[buf].buftype
	local name = vim.api.nvim_buf_get_name(buf)

	if
		name:match("snacks_dashboard")
		or vim.tbl_contains(ignore_filetypes, ft)
		or vim.tbl_contains(ignore_buftypes, bt)
	then
		vim.b[buf].minitrailspace_disable = true

		if buf == vim.api.nvim_get_current_buf() then
			pcall(vim.fn.clearmatches)
		end
	end
end

-- Hook onto the earliest layout creation hooks
autocmd({ "BufNewFile", "BufReadPre", "BufWinEnter", "FileType", "BufEnter" }, {
	group = augroup,
	pattern = "*",
	callback = disable_trailspace,
})

-- Targeted trigger for when snacks dashboard starts initialization
autocmd("User", {
	group = augroup,
	pattern = "SnacksDashboardOpened",
	callback = disable_trailspace,
})
