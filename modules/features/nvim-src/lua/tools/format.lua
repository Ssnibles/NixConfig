-- Formatting (conform.nvim) and the autoformat toggles.

local conform = require("conform")
local util = require("util")

local M = {}

-- Autoformat state is module-local: no vim.g flags for other files to read.
local enabled = true
local disabled_ft = {}

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
		rust = { "rustfmt" },
		zig = { "zigfmt" },
		typst = { "typstyle" },
	},
	format_on_save = function(bufnr)
		local ft = vim.bo[bufnr].filetype
		if not enabled or disabled_ft[ft] then
			return
		end
		return { timeout_ms = 1000, lsp_format = "fallback" }
	end,
})

--- Format the buffer, using LSP formatting when no formatter is configured.
function M.format()
	conform.format({ lsp_format = "fallback" })
end

--- Toggle autoformat for every filetype.
function M.toggle()
	enabled = not enabled
	util.notify_toggle("Autoformat", enabled)
end

--- Toggle autoformat for the current filetype.
function M.toggle_ft()
	local ft = vim.bo.filetype
	if ft == "" then
		return
	end
	disabled_ft[ft] = not disabled_ft[ft]
	util.notify_toggle("Autoformat for " .. ft, not disabled_ft[ft])
end

vim.api.nvim_create_user_command("Format", function(opts)
	M.format()
	if opts.bang then
		vim.cmd("noautocmd write")
	end
end, { desc = "Format buffer (:Format! also saves)", bang = true })

return M
