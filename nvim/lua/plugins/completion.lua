-- =============================================================================
-- Completion & AI Configuration (NixOS Optimised)
-- =============================================================================
-- Plugins: blink.cmp (completion), luasnip (snippets), copilot.lua (AI)
--
-- Key conflict resolution:
--   blink uses <Tab>/<S-Tab> for menu navigation (super-tab preset)
--   blink uses <C-n>/<C-p> in cmdline for menu navigation
--   Copilot therefore must NOT use <C-n>/<C-p> or <Tab>
--   Copilot accept  → <M-y>   (unambiguous, works in insert mode)
--   Copilot next    → <M-]>
--   Copilot prev    → <M-[>
--   Copilot dismiss → <C-]>   (unchanged)
--
-- Ghost text:
--   blink ghost_text is DISABLED — when Copilot auto_trigger is on it shows
--   its own inline virtual text. Having both active produces different/
--   conflicting suggestions rendered on the same line.
--   Copilot inline suggestion is the single source of ghost text.
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
		keymap = { preset = "super-tab" },
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		cmdline = {
			keymap = {
				-- These only apply in the cmdline completion popup so they
				-- don't conflict with Copilot (Copilot is insert-mode only)
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
			-- Disabled: Copilot provides inline ghost text via auto_trigger.
			-- Having both active renders two competing suggestions on the
			-- same line and they are often different from each other.
			ghost_text = { enabled = false },
		},
	})
end)

-- ── copilot.lua (AI inline suggestions) ──────────────────────────────────
-- loader.setup("copilot", function(copilot)
-- 	copilot.setup({
-- 		panel = {
-- 			enabled = true,
-- 			auto_refresh = true,
-- 		},
-- 		suggestion = {
-- 			enabled = true,
-- 			-- auto_trigger shows Copilot's own virtual-text inline suggestion.
-- 			-- This is the single source of ghost text — blink's ghost_text is
-- 			-- disabled above to prevent them from conflicting.
-- 			auto_trigger = true,
-- 			hide_during_completion = true,
-- 			keymap = {
-- 				-- <M-y> to accept — does not overlap with blink's <Tab> or
-- 				-- any other completion binding
-- 				accept = "<M-y>",
-- 				-- <M-]>/<M-[> for cycling — free of blink's <C-n>/<C-p>
-- 				next = "<M-]>",
-- 				prev = "<M-[>",
-- 				dismiss = "<C-]>",
-- 			},
-- 		},
-- 		filetypes = {
-- 			yaml = false,
-- 			markdown = false,
-- 			help = false,
-- 			gitcommit = false,
-- 			gitrebase = false,
-- 			["."] = false,
-- 		},
-- 	})
-- end)

require("_copilot")
