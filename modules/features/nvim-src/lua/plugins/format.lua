vim.g.disable_autoformat = vim.g.disable_autoformat or false
vim.g.disable_autoformat_ft = vim.g.disable_autoformat_ft or {}

local conform = require("conform")
local util = require("util")

local prettier = { "prettierd", "prettier", stop_after_first = true }

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		c = { "clang-format" },
		cpp = { "clang-format" },
		html = prettier,
		css = prettier,
		scss = prettier,
		less = prettier,
		javascript = prettier,
		javascriptreact = prettier,
		typescript = prettier,
		typescriptreact = prettier,
		json = prettier,
		yaml = prettier,
		markdown = prettier,
		nix = { "nixfmt" },
		sh = { "shfmt" },
		kotlin = { "ktlint" },
		java = { "google-java-format" },
		-- cs = { "csharpier" }, -- csharpier is not installed; add it to extraPackages to enable
		rust = { "rustfmt" },
		zig = { "zigfmt" },
		typst = { "typstyle" },
		php = { "php_cs_fixer" },
	},
	formatters = {
		-- Without --no-interaction, php-cs-fixer prompts to create a config file
		-- / enable risky rules when it finds none, which hangs conform.
		php_cs_fixer = {
			args = { "fix", "--no-interaction", "--allow-risky=no", "--using-cache=no", "$FILENAME" },
		},
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
	conform.format({ lsp_format = "fallback" })
	if opts.bang then
		vim.cmd("noautocmd write")
	end
end, { desc = "Format buffer (:Format! also saves)", bang = true })

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	conform.format({ lsp_format = "fallback" })
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>tF", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	util.notify_toggle("Autoformat", not vim.g.disable_autoformat)
end, { desc = "Toggle autoformat (global)" })

vim.keymap.set("n", "<leader>tA", function()
	local ft = vim.bo.filetype
	if ft == "" then
		return
	end
	local disabled = vim.g.disable_autoformat_ft or {}
	disabled[ft] = not disabled[ft]
	vim.g.disable_autoformat_ft = disabled
	util.notify_toggle("Autoformat for " .. ft, not disabled[ft])
end, { desc = "Toggle autoformat for filetype" })
