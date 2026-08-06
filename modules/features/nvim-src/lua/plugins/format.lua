vim.g.disable_autoformat = vim.g.disable_autoformat or false
vim.g.disable_autoformat_ft = vim.g.disable_autoformat_ft or { c = true, cpp = true }

local conform = require("conform")

conform.setup({
	formatters_by_ft = {
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
