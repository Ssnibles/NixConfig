-- =============================================================================
-- Completion & AI Configuration (NixOS Optimized)
-- =============================================================================
-- Plugins: blink.cmp (Completion), luasnip (Snippets), copilot.lua (AI)
-- =============================================================================

local loader = require("lib.loader")

-- ── luasnip (snippet engine) ──────────────────────────────────────────────
loader.setup("luasnip", function(luasnip)
	luasnip.setup({
		history = true,
		delete_check_events = "TextChanged",
		updateevents = "TextChanged,TextChangedI",
	})
	-- Load VSCode style snippets
	require("luasnip.loaders.from_vscode").lazy_load()
end)

-- ── blink.cmp (Completion Engine) ─────────────────────────────────────────
loader.setup("blink.cmp", function(blink)
	blink.setup({
		keymap = { preset = "super-tab" },
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
				ghost_text = { enabled = false },
			},
		},
		completion = {
			menu = {
				auto_show = true,
				border = "rounded",
				draw = {
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
						},
					},
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = { border = "rounded" },
			},
			ghost_text = { enabled = true },
		},
	})
end)

-- ── copilot.lua (AI Inline Suggestions) ───────────────────────────────────
loader.setup("copilot", function(copilot)
	copilot.setup({
		panel = {
			enabled = false,
			auto_refresh = true,
		},
		suggestion = {
			enabled = true,
			auto_trigger = true,
			hide_during_completion = true,
			keymap = {
				accept = "<C-y>",
				next = "<C-n>",
				prev = "<C-p>",
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
