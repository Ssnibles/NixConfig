-- =============================================================================
-- Completion & AI Intelligence
-- =============================================================================
local loader = require("lib.loader")

loader.setup("luasnip", function(luasnip)
	luasnip.setup({
		history = true,
		delete_check_events = "TextChanged",
		updateevents = "TextChanged,TextChangedI",
	})
	require("luasnip.loaders.from_vscode").lazy_load()
end)

loader.setup("blink.cmp", {
	signature = { enabled = true, window = { border = "rounded" } },
	keymap = {
		preset = "none",
		["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
		["<C-e>"] = { "hide", "fallback" },
		["<CR>"] = { "accept", "fallback" },
		["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
		["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
		["<Up>"] = { "select_prev", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<C-n>"] = { "select_next", "fallback" },
		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },
	},
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
	completion = {
		menu = { border = "rounded" },
		documentation = { auto_show = true, window = { border = "rounded" } },
		ghost_text = { enabled = false },
	},
})

loader.setup("copilot", {
	suggestion = {
		enabled = true,
		auto_trigger = true,
		hide_during_completion = true,
		keymap = { accept = "<M-y>", next = "<M-]>", prev = "<M-[>", dismiss = "<C-]>" },
	},
})
