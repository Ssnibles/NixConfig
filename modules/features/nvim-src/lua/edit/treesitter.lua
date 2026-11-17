-- Treesitter textobjects, movement and the sticky context header.

local M = {}

require("nvim-treesitter-textobjects").setup({
	select = { lookahead = true },
	move = { set_jumps = true },
})

M.select = require("nvim-treesitter-textobjects.select")
M.move = require("nvim-treesitter-textobjects.move")

require("treesitter-context").setup({
	enable = true,
	max_lines = 4,
	min_window_height = 20,
	separator = "─",
	on_attach = function(buf)
		local ft = vim.bo[buf].filetype
		return ft ~= "markdown" and ft ~= "markdown.mdx"
	end,
})

return M
