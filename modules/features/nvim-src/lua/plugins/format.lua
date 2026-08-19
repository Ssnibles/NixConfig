vim.g.disable_autoformat = vim.g.disable_autoformat or false
vim.g.disable_autoformat_ft = vim.g.disable_autoformat_ft or { c = true, cpp = true }

local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		html = { "prettierd", "prettier", stop_after_first = true },
		css = { "prettierd", "prettier", stop_after_first = true },
		scss = { "prettierd", "prettier", stop_after_first = true },
		less = { "prettierd", "prettier", stop_after_first = true },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		json = { "prettierd", "prettier", stop_after_first = true },
		yaml = { "prettierd", "prettier", stop_after_first = true },
		markdown = { "prettierd", "prettier", stop_after_first = true },
		nix = { "nixfmt" },
		sh = { "shfmt" },
		kotlin = { "ktlint" },
		java = { "google-java-format" },
		cs = { "csharpier" },
		rust = { "rustfmt" },
		zig = { "zigfmt" },
		typst = { "typstyle" },
	},
	format_on_save = function(bufnr)
		local ft = vim.bo[bufnr].filetype
		if vim.g.disable_autoformat or vim.g.disable_autoformat_ft[ft] then
			return
		end
		return { timeout_ms = 1000, lsp_format = "fallback" }
	end,
})

vim.api.nvim_create_user_command("Format", function(opts)
	conform.format({ bufnr = 0, lsp_format = "fallback" })
	if opts.bang then
		vim.cmd("noautocmd write")
	end
end, { desc = "Format buffer (:Format! also saves)", bang = true })

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	conform.format({ bufnr = 0, lsp_format = "fallback" })
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
