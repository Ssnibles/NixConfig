-- Treesitter: syntax highlighting and text objects

require("nvim-treesitter.configs").setup({
	highlight = { enable = true },
	indent = { enable = true },
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
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
			goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
		},
	},
})

-- Treesitter context: sticky headers
require("treesitter-context").setup({
	enable = true,
	max_lines = 4,
	min_window_height = 20,
	separator = "─",
})
