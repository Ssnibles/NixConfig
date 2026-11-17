-- Shared helpers.

local M = {}

--- Report a toggle's new state in a consistent format.
--- @param name string Human-readable feature name
--- @param enabled boolean Whether the feature is now enabled
function M.notify_toggle(name, enabled)
	vim.notify(("%s %s"):format(name, enabled and "enabled" or "disabled"))
end

-- Helper buffers: pickers, tool panes and plugin UIs. They are never editor
-- buffers, so buffer pickers and jump targets skip them.
local helper_filetypes = {
	fzf = true,
	oil = true,
	qf = true,
	help = true,
	jj = true,
	["grug-far"] = true,
}

--- @param filetype string
--- @return boolean
function M.is_helper_ft(filetype)
	return helper_filetypes[filetype] == true or filetype:find("^grug%-far") ~= nil
end

local lsp_capabilities

--- LSP client capabilities shared by `vim.lsp.config`, nvim-jdtls and
--- rustaceanvim. Built once and copied, because clients may mutate them.
--- @return table
function M.lsp_capabilities()
	if not lsp_capabilities then
		local capabilities = require("blink.cmp").get_lsp_capabilities()
		capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
		capabilities.textDocument.semanticTokens = { requests = { range = true, full = { delta = true } } }
		lsp_capabilities = capabilities
	end
	return vim.deepcopy(lsp_capabilities)
end

return M
