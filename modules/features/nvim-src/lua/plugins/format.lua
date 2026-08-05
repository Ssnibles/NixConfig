vim.g.disable_autoformat = vim.g.disable_autoformat or false
vim.g.disable_autoformat_ft = vim.g.disable_autoformat_ft or { c = true, cpp = true }

local formatters_by_ft = {
	lua = { "stylua" },
	python = { "isort", "black" },
	javascript = { "prettierd" },
	javascriptreact = { "prettierd" },
	typescript = { "prettierd" },
	typescriptreact = { "prettierd" },
	css = { "prettierd" },
	json = { "prettierd" },
	yaml = { "prettierd" },
	markdown = { "prettierd" },
	nix = { "nixfmt" },
	sh = { "shfmt" },
	kotlin = { "ktlint" },
	java = { "google-java-format" },
	cs = { "csharpier" },
	rust = { "rustfmt" },
	typst = { "typstyle" },
}

local function format_with_shell(bufnr, fmt)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local text = table.concat(lines, "\n")

	local args = { fmt }
	if name ~= "" then
		table.insert(args, "--stdin-filepath")
		table.insert(args, name)
	end

	local obj = vim.system(args, { stdin = text }):wait()
	if obj.code ~= 0 then
		return false
	end

	local result = vim.split(obj.stdout or "", "\n")
	if result[#result] == "" then
		table.remove(result)
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, result)
	return true
end

local function format_buffer(opts)
	opts = opts or {}
	local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
	local force = opts.force or false
	local ft = vim.bo[bufnr].filetype

	if not force and (vim.g.disable_autoformat or vim.g.disable_autoformat_ft[ft]) then
		return
	end

	local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
	if #clients > 0 then
		vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 1000 })
		return
	end

	local formatters = formatters_by_ft[ft]
	if not formatters then
		if not opts.silent then
			vim.notify("No formatter configured for " .. ft, vim.log.levels.WARN)
		end
		return
	end

	for _, fmt in ipairs(formatters) do
		if vim.fn.executable(fmt) == 1 and format_with_shell(bufnr, fmt) then
			return
		end
	end

	if not opts.silent then
		vim.notify("Formatter failed for " .. ft, vim.log.levels.WARN)
	end
end

vim.api.nvim_create_user_command("Format", function(opts)
	format_buffer({ force = true })
	if opts.bang then
		vim.cmd("noautocmd write")
	end
end, { desc = "Format buffer (:Format! also saves)", bang = true })

local format_group = vim.api.nvim_create_augroup("UserFormat", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = format_group,
	callback = function()
		format_buffer({ force = false, silent = true })
	end,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	format_buffer({ force = true })
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>tF", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	local msg = vim.g.disable_autoformat and "disabled" or "enabled"
	vim.notify(("Autoformat %s"):format(msg), vim.log.levels.INFO)
end, { desc = "Toggle autoformat (global)" })

vim.keymap.set("n", "<leader>tA", function()
	local ft = vim.bo.filetype
	if ft == "" then
		return
	end
	vim.g.disable_autoformat_ft[ft] = not vim.g.disable_autoformat_ft[ft]
	local msg = vim.g.disable_autoformat_ft[ft] and "disabled" or "enabled"
	vim.notify(("Autoformat for %s %s"):format(ft, msg), vim.log.levels.INFO)
end, { desc = "Toggle autoformat for filetype" })
