-- =============================================================================
-- Treesitter Configuration
-- =============================================================================
-- Syntax highlighting, indentation, and text objects powered by tree-sitter.
-- Provides language-aware editing features across all supported filetypes.
-- =============================================================================

local loader = require("lib.loader")

loader.setup("nvim-treesitter.configs", function(ts)
	ts.setup({
		highlight = { enable = true },
		indent = { enable = false }, -- IBL handles this
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["af"] = { query = "@function.outer" },
					["if"] = { query = "@function.inner" },
					["ac"] = { query = "@class.outer" },
					["ic"] = { query = "@class.inner" },
					["aa"] = { query = "@parameter.outer" },
					["ia"] = { query = "@parameter.inner" },
					["ab"] = { query = "@block.outer" },
					["ib"] = { query = "@block.inner" },
				},
			},
			move = {
				enable = true,
				set_jumps = true,
				goto_next_start = {
					["]f"] = { query = "@function.outer" },
					["]c"] = { query = "@class.outer" },
				},
				goto_previous_start = {
					["[f"] = { query = "@function.outer" },
					["[c"] = { query = "@class.outer" },
				},
			},
		},
	})
end)

-- treesitter-context (sticky headers)
loader.setup("treesitter-context", function(context)
	context.setup({
		enable = true,
		max_lines = 3,
		min_window_height = 15,
		mode = "cursor",
	})
end)
