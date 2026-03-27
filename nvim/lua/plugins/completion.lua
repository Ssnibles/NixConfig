-- =============================================================================
-- Completion & AI Configuration (NixOS Optimised)
-- =============================================================================
-- Plugins: blink.cmp (completion), luasnip (snippets), copilot.lua (AI)
-- =============================================================================

local loader = require("lib.loader")

-- ── luasnip (snippet engine) ──────────────────────────────────────────────
loader.setup("luasnip", function(luasnip)
	luasnip.setup({
		history = true,
		delete_check_events = "TextChanged",
		updateevents = "TextChanged,TextChangedI",
	})
	-- Load VSCode-style snippets from friendly-snippets (if available)
	require("luasnip.loaders.from_vscode").lazy_load()
end)

-- ── blink.cmp (completion engine) ─────────────────────────────────────────
loader.setup("blink.cmp", function(blink)
	blink.setup({
		-- Show function signatures for better context during development
		signature = { enabled = true },

		-- Navigation and acceptance keymaps restored to your previous preferences
		keymap = {
			preset = "none",
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },

			-- Primary acceptance key
			["<Tab>"] = { "accept", "fallback" },

			-- Standard directional navigation for completion items
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },

			-- Snippet placeholder navigation
			["<S-Tab>"] = { "snippet_backward", "fallback" },

			-- Documentation scrolling
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		cmdline = {
			keymap = {
				-- Command-line specific navigation and acceptance
				["<Tab>"] = { "accept", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
			},
			completion = {
				menu = { auto_show = true },
				ghost_text = { enabled = true },
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
			ghost_text = { enabled = true },
		},
	})
end)

-- ── copilot.lua (AI inline suggestions) ──────────────────────────────────
loader.setup("copilot", function(copilot)
	copilot.setup({
		panel = {
			enabled = true,
			auto_refresh = true,
		},
		suggestion = {
			enabled = true,
			-- auto_trigger shows Copilot's own virtual-text inline suggestion.
			-- This is the single source of ghost text — blink's ghost_text is
			-- disabled above to prevent them from conflicting.
			auto_trigger = true,
			hide_during_completion = true,
			keymap = {
				-- <M-y> to accept — does not overlap with blink's <Tab> or
				-- any other completion binding
				accept = "<M-y>",
				-- <M-]>/<M-[> for cycling — free of blink's <C-n>/<C-p>
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

-- require("_copilot")
