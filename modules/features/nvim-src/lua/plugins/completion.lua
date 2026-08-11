require("luasnip").setup({
	history = true,
	region_check_events = "InsertEnter,TextChangedI",
	delete_check_events = "InsertLeave",
})

require("luasnip.loaders.from_vscode").lazy_load()

local cmp = require("blink.cmp")

local keymap = {
    preset = "none",

    -- Open completion menu manually
    ["<C-space>"] = {
        function()
            cmp.show({ providers = { "lsp", "copilot", "snippets", "buffer", "path" } })
        end,
    },

    -- Tab accepts completion when menu is visible; falls back to regular Tab
    ["<Tab>"] = {
        function()
            if cmp.is_visible() then
                return cmp.accept()
            end
        end,
        "fallback",
    },

    -- Snippet navigation (Forward: Ctrl+L, Backward: Ctrl+H)
    ["<C-l>"] = { "snippet_forward", "fallback" },
    ["<C-h>"] = { "snippet_backward", "fallback" },

    -- Menu selection and cancel options
    ["<Esc>"] = { "cancel", "fallback" },
    ["<C-c>"] = { "cancel", "fallback" },
    ["<C-e>"] = { "cancel", "fallback" },
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
	signature = {
		enabled = true,
		window = { border = "rounded", show_documentation = true },
	},
	snippets = { preset = "luasnip" },
	keymap = keymap,
	appearance = {
		nerd_font_variant = "mono",
		kind_icons = {
			Text = "󰉿",
			Method = "󰆧",
			Function = "󰊕",
			Constructor = "",
			Field = "󰜢",
			Variable = "󰀫",
			Class = "󰠱",
			Interface = "",
			Module = "",
			Property = "󰜢",
			Unit = "󰑭",
			Value = "󰎠",
			Enum = "",
			Keyword = "󰌋",
			Snippet = "",
			Color = "󰏘",
			File = "󰈙",
			Folder = "󰉋",
			Reference = "󰈇",
			EnumMember = "",
			Constant = "󰏿",
			Struct = "󰙅",
			Event = "",
			Operator = "󰆕",
			TypeParameter = "󰊄",
		},
	},

	sources = {
		default = { "lsp", "copilot", "snippets", "buffer", "path" },
		per_filetype = {
			typst = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
			markdown = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
			text = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
			gitcommit = { "lsp", "copilot", "snippets", "buffer", "path", "spell" },
		},
		providers = {
			copilot = {
				name = "copilot",
				module = "blink-cmp-copilot",
				score_offset = 100,
				async = true,
			},
			spell = {
				name = "Spell",
				module = "blink-cmp-spell",
				enabled = function()
					return vim.wo.spell
				end,
				opts = { max_entries = 8 },
			},
			buffer = {
				max_items = 8,
				min_keyword_length = 3,
				score_offset = -3,
			},
			snippets = {
				min_keyword_length = 1,
				score_offset = 10,
			},
			path = {
				min_keyword_length = 2,
				score_offset = -2,
			},
		},
	},
	completion = {
		list = {
			selection = {
				preselect = function(ctx)
					return ctx.mode ~= "cmdline"
				end,
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
			show_with_selection = true, -- Only show ghost text when an item is actively selected/highlighted
			show_without_selection = false, -- Do not show ghost text immediately upon menu popup
		},
	},
	cmdline = {
		keymap = keymap,
		completion = {
			menu = { auto_show = true },
			ghost_text = { enabled = true },
		},
	},
})

local ok_text_edits, text_edits = pcall(require, "blink.cmp.lib.text_edits")
if ok_text_edits then
	local original_write_to_dot_repeat = text_edits.write_to_dot_repeat
	text_edits.write_to_dot_repeat = function(text_edit)
		if vim.fn.mode() ~= "i" then
			return
		end
		return original_write_to_dot_repeat(text_edit)
	end
end

local copilot_ok, copilot = pcall(require, "copilot")
if copilot_ok then
	copilot.setup({
		suggestion = { enabled = false },
		panel = { enabled = true },
	})
end

vim.keymap.set("n", "<leader>ac", function()
	if not copilot_ok then
		return
	end
	copilot.suggestion.toggle()
	local status = copilot.suggestion.is_enabled() and "enabled" or "disabled"
	vim.notify(("Copilot %s"):format(status), vim.log.levels.INFO)
end, { desc = "Toggle copilot" })

vim.keymap.set("n", "<leader>ap", function()
	if copilot_ok then
		copilot.panel.toggle()
	end
end, { desc = "Toggle copilot panel" })
