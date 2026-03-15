-- nvim-treesitter — syntax highlighting, smart indentation, and text objects.
-- Parsers are installed via modules/neovim.nix (withPlugins), not here.

local ok, ts = pcall(require, "nvim-treesitter.configs")
if not ok then
	return
end

ts.setup({
	highlight = { enable = true },
	indent = { enable = true },

	-- nvim-treesitter-textobjects: @function.outer / @class.inner etc.
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["af"] = { query = "@function.outer", desc = "Around function" },
				["if"] = { query = "@function.inner", desc = "Inside function" },
				["ac"] = { query = "@class.outer", desc = "Around class" },
				["ic"] = { query = "@class.inner", desc = "Inside class" },
				["aa"] = { query = "@parameter.outer", desc = "Around argument" },
				["ia"] = { query = "@parameter.inner", desc = "Inside argument" },
				["ab"] = { query = "@block.outer", desc = "Around block" },
				["ib"] = { query = "@block.inner", desc = "Inside block" },
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = {
				["]f"] = { query = "@function.outer", desc = "Next function start" },
				["]c"] = { query = "@class.outer", desc = "Next class start" },
				["]a"] = { query = "@parameter.inner", desc = "Next argument" },
			},
			goto_previous_start = {
				["[f"] = { query = "@function.outer", desc = "Prev function start" },
				["[c"] = { query = "@class.outer", desc = "Prev class start" },
				["[a"] = { query = "@parameter.inner", desc = "Prev argument" },
			},
		},
	},
})

-- nvim-treesitter-context: sticky scope header at the top of the window.
-- Highlight colours are left entirely to the active colourscheme.
local ctx_ok, ctx = pcall(require, "treesitter-context")
if ctx_ok then
	ctx.setup({
		max_lines = 5, -- show up to 5 lines of nesting context
		min_window_height = 20, -- only show in tall enough windows
		trim_scope = "outer",
		multiline_threshold = 1,
		separator = "─", -- subtle separator line below the context block
		mode = "cursor", -- updates as cursor moves, not just on scroll
	})
	vim.keymap.set("n", "[C", function()
		ctx.go_to_context(vim.v.count1)
	end, { silent = true, desc = "Jump to context" })
end
