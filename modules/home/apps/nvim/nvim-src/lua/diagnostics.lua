vim.diagnostic.config({
	virtual_text = {
		enabled = true,
		spacing = 6,
		prefix = function(diagnostic)
			local sev = diagnostic.severity
			if sev == vim.diagnostic.severity.ERROR then
				return "▎× ", "DiagnosticVirtualTextError"
			elseif sev == vim.diagnostic.severity.WARN then
				return "▎▲ ", "DiagnosticVirtualTextWarn"
			elseif sev == vim.diagnostic.severity.HINT then
				return "▎• ", "DiagnosticVirtualTextHint"
			else
				return "▎• ", "DiagnosticVirtualTextInfo"
			end
		end,
		format = function(diagnostic)
			local msg = diagnostic.message
			return msg and msg:gsub("%s+", " "):gsub("\n", " ") or ""
		end,
	},
	underline = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "×",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.HINT] = "•",
			[vim.diagnostic.severity.INFO] = "•",
		},
	},
	severity_sort = true,
	float = { border = "rounded", source = true, max_width = 60 },
	update_in_insert = false,
})
