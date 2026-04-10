-- Completion: blink.cmp, copilot, snippets

-- Snippets
require("luasnip").setup({
	history = true,
	delete_check_events = "TextChanged",
})
require("luasnip.loaders.from_vscode").lazy_load()

-- Blink.cmp: fast completion
require("blink.cmp").setup({
	signature = { enabled = true, window = { border = "rounded", show_documentation = true } },
	keymap = {
		preset = "none",
		["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
		["<C-e>"] = { "cancel", "fallback" },
		["<Esc>"] = { "cancel", "fallback" },
		["<CR>"] = { "accept", "fallback" },
		["<Tab>"] = { "snippet_forward", "accept", "select_next", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<C-n>"] = { "select_next", "fallback" },
		["<Up>"] = { "select_prev", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },
	},
	sources = { default = { "lsp", "path", "snippets", "buffer" } },
	completion = {
		menu = {
			auto_show = true,
			border = "rounded",
			scrollbar = true,
			draw = {
				columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
			},
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 200,
			window = { border = "rounded" },
		},
		ghost_text = { enabled = false },
	},
	cmdline = {
		keymap = {
			["<Tab>"] = { "accept", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
		},
		completion = { menu = { auto_show = true }, ghost_text = { enabled = false } },
	},
})

-- Copilot
require("copilot").setup({
	suggestion = {
		enabled = true,
		auto_trigger = true,
		debounce = 150,
		hide_during_completion = true,
		keymap = {
			accept = "<M-y>",
			next = "<M-]>",
			prev = "<M-[>",
			dismiss = "<C-]>",
		},
	},
	panel = { enabled = false },
})
