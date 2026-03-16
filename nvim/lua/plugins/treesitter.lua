-- =============================================================================
-- Treesitter Configuration
-- =============================================================================
-- Syntax highlighting, text objects, and context display. Parsers are
-- installed via Nix modules/neovim.nix withPlugins, not here.
-- Note: indent is disabled to allow IBL to handle scope detection correctly.

local ok, ts = pcall(require, "nvim-treesitter.configs")
if not ok then
	return
end

ts.setup({
	-- Enable syntax highlighting
	highlight = { enable = true },

	-- Disable indent (IBL handles scope detection instead)
	indent = { enable = false },

	-- Text objects for functions, classes, parameters, and blocks
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

-- ── Treesitter Context ─────────────────────────────────────────────────────
-- Sticky scope header at top of window showing current function/class context
local ctx_ok, ctx = pcall(require, "treesitter-context")
if ctx_ok then
	ctx.setup({
		enable = true,
		max_lines = 3,
		min_window_height = 15,
		trim_scope = "outer",
		multiline_threshold = 1,
		separator = "",
		mode = "cursor",
		zindex = 1,
	})
	vim.keymap.set("n", "[C", function()
		ctx.go_to_context(vim.v.count1)
	end, { silent = true, desc = "Jump to context" })
end
