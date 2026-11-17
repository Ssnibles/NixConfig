-- Diagnostics, toggles, LSP commands, formatting and linting.
local map = vim.keymap.set
local util = require("util")
-- Diagnostics
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
local function jump(count, severity)
	vim.diagnostic.jump({
		count = count,
		severity = severity,
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
		end,
	})
end
map("n", "]d", function()
	jump(1)
end, { desc = "Next diagnostic" })
map("n", "[d", function()
	jump(-1)
end, { desc = "Previous diagnostic" })
map("n", "]e", function()
	jump(1, vim.diagnostic.severity.ERROR)
end, { desc = "Next error" })
map("n", "[e", function()
	jump(-1, vim.diagnostic.severity.ERROR)
end, { desc = "Previous error" })
-- Toggles
map("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle wrap" })
map("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell" })
map("n", "<leader>tn", function()
	local enabled = not vim.wo.relativenumber
	vim.w.relativenumber_enabled = enabled
	vim.wo.relativenumber = enabled
	util.notify_toggle("Relative numbers", enabled)
end, { desc = "Toggle relative numbers" })
map("n", "<leader>td", function()
	require("diagnostics").toggle()
end, { desc = "Toggle diagnostics" })
map("n", "<leader>tD", function()
	require("diagnostics").toggle_inline()
end, { desc = "Toggle inline diagnostics" })
map("n", "<leader>ti", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local enabled = not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
	vim.lsp.inlay_hint.enable(enabled, { bufnr = bufnr })
	util.notify_toggle("Inlay hints", enabled)
end, { desc = "Toggle inlay hints" })
map("n", "<leader>tc", function()
	vim.b.minicursorword_disable = not vim.b.minicursorword_disable
	util.notify_toggle("Cursor word highlighting", not vim.b.minicursorword_disable)
end, { desc = "Toggle cursor word" })
map("n", "<leader>tF", function()
	require("tools.format").toggle()
end, { desc = "Toggle autoformat (global)" })
map("n", "<leader>tA", function()
	require("tools.format").toggle_ft()
end, { desc = "Toggle autoformat for filetype" })
-- LSP (outside attached buffers)
map("n", "<leader>lr", function()
	if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
		vim.notify("No LSP client attached to this buffer", vim.log.levels.WARN)
		return
	end
	vim.cmd("lsp restart")
end, { desc = "Restart LSP" })
map("n", "<leader>lf", "<cmd>FzfLua lsp_finder<CR>", { desc = "LSP finder" })
map("n", "<leader>lh", "<cmd>LspHealth<CR>", { desc = "LSP health" })
map("n", "<leader>lR", "<cmd>SmartRename<CR>", { desc = "Smart rename/replace" })
-- Format and lint
map({ "n", "v" }, "<leader>cf", function()
	require("tools.format").format()
end, { desc = "Format buffer" })
map("n", "<leader>cL", function()
	require("tools.lint").run_and_notify()
end, { desc = "Lint buffer" })
