require("luasnip").setup({
	history = true,
	region_check_events = "InsertEnter,TextChangedI",
	delete_check_events = "InsertLeave",
})
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").lazy_load({
	paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
})

-- ── Blink.cmp ────────────────────────────────────────────────────────

local cmp = require("blink.cmp")
local ls = require("luasnip")

-- Global LuaSnip jump as fallback in insert & snippet selection modes
vim.keymap.set({ "i", "s" }, "<C-]>", function()
	if ls.locally_jumpable(1) then
		ls.jump(1)
	end
end, { desc = "Snippet forward", silent = true })

local keymap = {
	preset = "none",
	["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
	["<CR>"] = { "fallback" },
	["<Tab>"] = { "select_and_accept", "fallback" },
	["<C-]>"] = { "snippet_forward", "fallback" },
	["<S-Tab>"] = { "fallback" },
	["<Esc>"] = {
		function(cmp)
			if cmp.is_visible() then
				cmp.cancel()
			end
		end,
		"fallback",
	},
	["<C-c>"] = {
		function(cmp)
			if cmp.is_visible() then
				cmp.cancel()
			end
		end,
		"fallback",
	},
	["<C-e>"] = { "cancel", "fallback" },
	["<C-y>"] = { "select_and_accept", "fallback" },
	["<Up>"] = { "select_prev", "fallback" },
	["<Down>"] = { "select_next", "fallback" },
	["<C-p>"] = { "select_prev", "fallback" },
	["<C-n>"] = { "select_next", "fallback" },
	["<C-k>"] = { "select_prev", "fallback" },
	["<C-j>"] = { "select_next", "fallback" },
	["<C-b>"] = { "scroll_documentation_up", "fallback" },
	["<C-f>"] = { "scroll_documentation_down", "fallback" },
}

cmp.setup({
	signature = { enabled = true, window = { border = "rounded", show_documentation = true } },
	snippets = { preset = "luasnip" },
	keymap = keymap,
	appearance = {
		nerd_font_variant = "mono",
		kind_icons = {
			Text = "󰉿",
			Method = "󰆧",
			Function = "󰊕",
			Constructor = "󰒓",
			Field = "󰜢",
			Variable = "󰀫",
			Class = "󰠱",
			Interface = "󱡠",
			Module = "󰅩",
			Property = "󰜢",
			Unit = "󰑭",
			Value = "󰎠",
			Enum = "󰦨",
			EnumMember = "󰦨",
			Keyword = "󰌋",
			Snippet = "󱄽",
			Color = "󰏘",
			File = "󰈙",
			Folder = "󰉋",
			Reference = "󰈇",
			Constant = "󰏿",
			Struct = "󰙅",
			Event = "󱐋",
			Operator = "󰆕",
			TypeParameter = "󰊄",
			Copilot = "",
		},
	},
	fuzzy = {
		implementation = "prefer_rust_with_warning",
		use_proximity = true,
		sorts = { "exact", "score", "sort_text" },
	},
	sources = {
		-- Context-aware: in comments, suppress LSP symbol noise and favor prose/buffer/spell/copilot
		default = function()
			local ok, node = pcall(vim.treesitter.get_node)
			if ok and node then
				local node_type = node:type()
				if node_type:match("comment") then
					return { "buffer", "copilot", "spell" }
				end
			end
			return { "lsp", "copilot", "snippets", "buffer", "path" }
		end,
		per_filetype = {
			typst = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
			markdown = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
			text = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
			gitcommit = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
		},
		providers = {
			lsp = {
				name = "LSP",
				module = "blink.cmp.sources.lsp",
				score_offset = 100,
				fallbacks = { "buffer" },
			},
			copilot = {
				name = "copilot",
				module = "blink-cmp-copilot",
				score_offset = 80,
				async = true,
			},
			snippets = {
				name = "Snippets",
				module = "blink.cmp.sources.snippets",
				min_keyword_length = 2,
				score_offset = 60,
				opts = {
					use_label_description = true,
				},
			},
			path = {
				name = "Path",
				module = "blink.cmp.sources.path",
				min_keyword_length = 2,
				score_offset = 70,
				fallbacks = { "buffer" },
				opts = {
					show_hidden_files_by_default = true,
				},
			},
			buffer = {
				name = "Buffer",
				module = "blink.cmp.sources.buffer",
				max_items = 5,
				min_keyword_length = 3,
				score_offset = -5,
			},
			spell = {
				name = "Spell",
				module = "blink-cmp-spell",
				enabled = function() return vim.wo.spell end,
				opts = { max_entries = 8 },
				score_offset = 10,
			},
		},
	},
	completion = {
		list = {
			selection = {
				preselect = function(ctx) return ctx.mode ~= "cmdline" end,
				auto_insert = false,
			},
		},
		menu = {
			auto_show = true,
			direction_priority = { "s", "n" },
			border = "rounded",
			scrollbar = true,
			draw = {
				padding = { 1, 1 },
				columns = { { "kind_icon", gap = 1 }, { "label", "label_description", gap = 1 }, { "kind" } },
			},
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 50,
			window = { border = "rounded", max_width = 80, max_height = 30 },
		},
		ghost_text = {
			enabled = true,
			show_with_selection = true,
			show_without_selection = false,
		},
	},
	cmdline = {
		keymap = {
			preset = "none",
			["<CR>"] = { "fallback" },
			["<Tab>"] = { "select_and_accept", "fallback" },
			["<S-Tab>"] = { "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-e>"] = { "cancel", "fallback" },
			["<Esc>"] = false,
			["<C-c>"] = false,
		},
		completion = { menu = { auto_show = true }, ghost_text = { enabled = true } },
	},
})

-- ── Copilot ──────────────────────────────────────────────────────────

local copilot_ok, copilot = pcall(require, "copilot")
if copilot_ok then
	copilot.setup({ suggestion = { enabled = false }, panel = { enabled = true } })

	vim.keymap.set("n", "<leader>ac", function()
		copilot.suggestion.toggle()
		vim.notify("Copilot " .. (copilot.suggestion.is_enabled() and "enabled" or "disabled"))
	end, { desc = "Toggle copilot" })

	vim.keymap.set("n", "<leader>ap", function()
		copilot.panel.toggle()
	end, { desc = "Toggle copilot panel" })
end


