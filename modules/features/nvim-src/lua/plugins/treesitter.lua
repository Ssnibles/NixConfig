require("nvim-treesitter-textobjects").setup({
	select = { lookahead = true },
	move = { set_jumps = true },
})

local ts_select = require("nvim-treesitter-textobjects.select")
local ts_move = require("nvim-treesitter-textobjects.move")

local select_keymaps = {
	["af"] = { query = "@function.outer", desc = "Around function" },
	["if"] = { query = "@function.inner", desc = "Inside function" },
	["ac"] = { query = "@class.outer", desc = "Around class" },
	["ic"] = { query = "@class.inner", desc = "Inside class" },
	["aa"] = { query = "@parameter.outer", desc = "Around parameter" },
	["ia"] = { query = "@parameter.inner", desc = "Inside parameter" },
}
for key, spec in pairs(select_keymaps) do
	vim.keymap.set({ "o", "x" }, key, function() ts_select.select_textobject(spec.query) end, { silent = true, desc = spec.desc })
end

vim.keymap.set({ "n", "o", "x" }, "]f", function() ts_move.goto_next_start("@function.outer") end, { silent = true, desc = "Next function" })
vim.keymap.set({ "n", "o", "x" }, "[f", function() ts_move.goto_previous_start("@function.outer") end, { silent = true, desc = "Previous function" })
vim.keymap.set({ "n", "o", "x" }, "]c", function() ts_move.goto_next_start("@class.outer") end, { silent = true, desc = "Next class" })
vim.keymap.set({ "n", "o", "x" }, "[c", function() ts_move.goto_previous_start("@class.outer") end, { silent = true, desc = "Previous class" })

require("treesitter-context").setup({
	enable = true, max_lines = 4, min_window_height = 20, separator = "─",
	on_attach = function(buf)
		local ft = vim.bo[buf].filetype
		return ft ~= "markdown" and ft ~= "markdown.mdx"
	end,
})

