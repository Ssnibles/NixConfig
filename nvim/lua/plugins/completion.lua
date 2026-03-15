-- =============================================================================
-- Completion and Highlight Configuration
-- =============================================================================
-- blink.cmp setup for async completion.
-- Highlight overrides are now centralized in lib/highlights.lua

-- ── blink.cmp Configuration ────────────────────────────────────────────────
require("blink.cmp").setup({
	-- Use Super-Tab style keybindings for completion navigation
	keymap = { preset = "super-tab" },
	-- Command-line completion settings
	cmdline = {
		keymap = {
			["<Tab>"] = { "accept", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
		},
		completion = {
			menu = { auto_show = true },
			ghost_text = { enabled = true },
		},
	},
	-- Completion menu and documentation window settings
	completion = {
		menu = {
			auto_show = true,
			border = "rounded",
			winhighlight = "Normal:BlinkMenuNormal,FloatBorder:BlinkMenuBorder,CursorLine:BlinkMenuSel,Search:None",
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 100,
			window = {
				border = "rounded",
				winhighlight = "Normal:BlinkMenuNormal,FloatBorder:BlinkMenuBorder",
			},
		},
		ghost_text = { enabled = true },
	},
	-- Completion sources in priority order
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
})

-- Load VS Code-format snippets from friendly-snippets
require("luasnip.loaders.from_vscode").lazy_load()
