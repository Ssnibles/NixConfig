-- Blink.cmp sources. In comments, drop the LSP symbol noise and favour prose
-- sources. The spell provider only runs when 'spell' is on.

return {
	-- Context-aware: suppress LSP symbol noise and favour prose in comments.
	default = function()
		local ok, node = pcall(vim.treesitter.get_node)
		if ok and node and node:type():match("comment") then
			return { "buffer", "copilot", "spell" }
		end
		return { "lsp", "copilot", "snippets", "buffer", "path", "spell" }
	end,
	providers = {
		lsp = {
			name = "LSP",
			module = "blink.cmp.sources.lsp",
			score_offset = 100,
			fallbacks = { "buffer" },
		},
		copilot = {
			name = "copilot",
			module = "blink-cmp-copilot",
			score_offset = 80,
			async = true,
		},
		snippets = {
			name = "Snippets",
			module = "blink.cmp.sources.snippets",
			min_keyword_length = 2,
			score_offset = 60,
			opts = { use_label_description = true },
		},
		path = {
			name = "Path",
			module = "blink.cmp.sources.path",
			min_keyword_length = 2,
			score_offset = 70,
			fallbacks = { "buffer" },
			opts = { show_hidden_files_by_default = true },
		},
		buffer = {
			name = "Buffer",
			module = "blink.cmp.sources.buffer",
			max_items = 5,
			min_keyword_length = 3,
			score_offset = -5,
		},
		spell = {
			name = "Spell",
			module = "blink-cmp-spell",
			enabled = function()
				return vim.wo.spell
			end,
			opts = { max_entries = 8 },
			score_offset = 10,
		},
	},
}
