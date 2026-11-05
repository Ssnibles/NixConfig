-- Shared LSP client capabilities.
-- Built once from blink.cmp and reused by the global client config, the server
-- table, and rustaceanvim.

local capabilities = require("blink.cmp").get_lsp_capabilities()

capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
capabilities.textDocument.semanticTokens = { requests = { range = true, full = { delta = true } } }

return capabilities
