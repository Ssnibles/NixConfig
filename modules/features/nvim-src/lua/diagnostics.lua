vim.diagnostic.config({
	virtual_text = {
		spacing = 4,
		prefix = "●",
		severity = { min = vim.diagnostic.severity.WARN },
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
	float = {
		border = "rounded",
		source = "if_many",
		max_width = 70,
	},
	update_in_insert = false,
})
