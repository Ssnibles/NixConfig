-- =============================================================================
-- Completion & AI Configuration
-- =============================================================================
-- Ghost Text Strategy (VSCode/Zed pattern):
--   - Copilot handles ALL inline ghost text suggestions
--   - blink.cmp handles ONLY the completion dropdown menu
--   - This prevents competing ghost text from both sources
-- =============================================================================
local loader = require("lib.loader")

-- luasnip
loader.setup("luasnip", function(luasnip)
	luasnip.setup({
		history = true,
		delete_check_events = "TextChanged",
		updateevents = "TextChanged,TextChangedI",
	})
	require("luasnip.loaders.from_vscode").lazy_load()
end)

-- blink.cmp
loader.setup("blink.cmp", function(blink)
	blink.setup({
		signature = { enabled = true },
		keymap = {
			preset = "none",
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
			["<Tab>"] = { "accept", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "snippet_backward", "fallback" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		cmdline = {
			keymap = {
				["<Tab>"] = { "accept", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
			},
			completion = {
				menu = { auto_show = true },
				ghost_text = { enabled = false }, -- FIXED: Disabled, Copilot handles inline
			},
		},
		completion = {
			menu = {
				auto_show = true,
				border = "rounded",
				draw = {
					columns = { { "kind_icon", gap = 1 }, { "label", "label_description", gap = 1 } },
					components = {
						kind_icon = {
							text = function(ctx)
								local icons = {
									Text = "󰉿",
									Method = "󰆧",
									Function = "󰆧",
									Constructor = "󰆧",
									Field = "󰜢",
									Variable = "󰀫",
									Class = "󰠱",
									Interface = "󰠱",
									Module = "󰕳",
									Property = "󰜢",
									Unit = "󰑭",
									Value = "󰎠",
									Enum = "󰕘",
									Keyword = "󰌋",
									Snippet = "󰩫",
									Color = "󰏘",
									File = "󰈙",
									Reference = "󰈇",
									Folder = "󰉋",
									EnumMember = "󰕘",
									Constant = "󰏿",
									Struct = "󰠱",
									Event = "󱐋",
									Operator = "󰆕",
									TypeParameter = "󰊄",
								}
								return icons[ctx.kind] or "󰌋"
							end,
							highlight = "Character",
						},
					},
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = { border = "rounded" },
			},
			ghost_text = { enabled = false }, -- FIXED: Disabled, Copilot handles inline
		},
	})
end)

-- copilot.lua
loader.setup("copilot", function(copilot)
	copilot.setup({
		panel = { enabled = true, auto_refresh = true },
		suggestion = {
			enabled = true,
			auto_trigger = true, -- Copilot's inline ghost text
			hide_during_completion = true,
			keymap = {
				accept = "<M-y>",
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<C-]>",
			},
		},
		filetypes = {
			yaml = false,
			markdown = false,
			help = false,
			gitcommit = false,
			gitrebase = false,
			["."] = false,
		},
	})
end)
