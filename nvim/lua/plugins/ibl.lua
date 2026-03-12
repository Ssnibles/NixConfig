-- ============================================================================
-- INDENT-BLANKLINE (indent guides)
-- Draws subtle vertical │ lines at each indent level.
-- The active scope (the block the cursor is currently inside) is highlighted
-- in vague keyword blue so it stands out without being distracting.
-- Highlight colours are defined in highlights.lua, which runs after the
-- colorscheme so vague doesn't reset them.
-- ============================================================================

require("ibl").setup({
	indent = {
		char = "│",
		highlight = "IblIndent",
	},
	scope = {
		enabled = true,
		-- Underline the scope's opening line rather than the default bold
		-- highlight — less intrusive, still clearly visible.
		show_start = true,
		show_end = false,
		highlight = "IblScope",
	},
	-- Don't show guides in UI buffers where they add noise.
	exclude = {
		filetypes = { "help", "dashboard", "lazy", "mason", "oil", "which-key" },
	},
})
