-- Shared LSP client capabilities.
-- Built once from blink.cmp (falling back to the built-in defaults) and reused
-- by the global client config, the server table, and rustaceanvim.

local lsp = vim.lsp

local ok, blink = pcall(require, "blink.cmp")
local capabilities = ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()

capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
capabilities.textDocument.semanticTokens = { requests = { range = true, full = { delta = true } } }

return capabilities
