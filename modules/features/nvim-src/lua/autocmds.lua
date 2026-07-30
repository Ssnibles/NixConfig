local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

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

		if bo.buftype ~= "" or name == "" then
			pcall(vim.cmd, "noautocmd write")
			writing = false
			return
		end

		vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buf, modeline = false })

		local ok, err = pcall(vim.cmd, "silent noautocmd write")

		vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf, modeline = false })

		writing = false

		if not ok then
			vim.notify("Write failed: " .. tostring(err), vim.log.levels.ERROR)
		end
	end,
})

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

autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank({ timeout = 200 })
	end,
})

autocmd({ "FocusGained" }, {
	group = augroup,
	command = "checktime",
})

autocmd("BufReadPost", {
	group = augroup,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

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
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		for i, line in ipairs(lines) do
			lines[i] = line:gsub("%s+$", "")
		end
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		-- trim trailing blank lines at end
		local last = #lines
		while last > 1 and lines[last]:match("^%s*$") do
			last = last - 1
		end
		if last < #lines then
			vim.api.nvim_buf_set_lines(0, last, -1, false, {})
		end
	end,
})

autocmd("FileType", {
	group = augroup,
	pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "oil", "grug-far", "NeogitStatus", "cargo" },
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
		vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
	end,
})

autocmd("VimResized", {
	group = augroup,
	command = "wincmd =",
})

autocmd("FileType", {
	group = augroup,
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "markdown.mdx", "text", "gitcommit" },
	callback = function(ev)
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
		if vim.fn.has("nvim-0.12") == 1 then
			if vim.bo[ev.buf].filetype == "markdown" or vim.bo[ev.buf].filetype == "markdown.mdx" then
				pcall(vim.treesitter.stop, ev.buf)
			end
		end
	end,
})

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

		vim.keymap.set("n", "<leader>zo", function()
			local buf_path = vim.fn.expand("%:p")
			local pdf_path = buf_path:gsub("%.typ$", ".pdf")
			if vim.fn.filereadable(pdf_path) == 1 then
				vim.fn.system({
					"zathura",
					"--synctex-forward=" .. vim.fn.line(".") .. ":0:" .. buf_path,
					pdf_path,
				})
			else
				vim.notify("PDF not found: " .. pdf_path, vim.log.levels.WARN)
			end
		end, { buffer = true, desc = "Open PDF in Zathura" })
	end,
})

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

vim.on_key(function(key, typed)
	local mode = vim.api.nvim_get_mode().mode
	local key_hex = string.format("%02x", string.byte(key))
	-- Log to a file so it doesn't interfere with the cmdline
	local f = io.open("/tmp/nvim_keys.log", "a")
	f:write(string.format("mode=%s key=%s hex=%s typed=%s\n", mode, key, key_hex, vim.inspect(typed)))
	f:close()
end)
