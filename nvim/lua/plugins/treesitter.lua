-- =============================================================================
-- Treesitter Configuration
-- =============================================================================
-- Syntax highlighting, indentation, and text objects powered by tree-sitter.
-- =============================================================================
local loader = require("lib.loader")

loader.setup("nvim-treesitter.configs", function(ts)
	ts.setup({
		highlight = { enable = true },
		indent = { enable = false },
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
					["aa"] = "@parameter.outer",
					["ia"] = "@parameter.inner",
					["ab"] = "@block.outer",
					["ib"] = "@block.inner",
				},
			},
			move = {
				enable = true,
				set_jumps = true,
				goto_next_start = {
					["]f"] = "@function.outer",
					["]c"] = "@class.outer",
				},
				goto_previous_start = {
					["[f"] = "@function.outer",
					["[c"] = "@class.outer",
				},
			},
		},
	})
end)

-- treesitter-context (sticky headers)
loader.setup("treesitter-context", {
	enable = true,
	max_lines = 4,
	min_window_height = 20,
	mode = "cursor",
	separator = "─", -- Subtle separator line
	zindex = 20,
	multiline_threshold = 1,
})
