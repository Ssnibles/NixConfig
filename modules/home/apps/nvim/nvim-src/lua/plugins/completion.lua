-- Completion: blink.cmp, luasnip snippets, copilot.

-- ═══════════════════════════════════════════════════════════════════
--  L U A S N I P
-- ═══════════════════════════════════════════════════════════════════

require("luasnip").setup({
	history = true,
	region_check_events = "InsertEnter,TextChangedI",
	delete_check_events = "InsertLeave",
})

require("luasnip.loaders.from_vscode").lazy_load()
require("plugins.typst-snippets")
require("plugins.java-snippets")

-- ═══════════════════════════════════════════════════════════════════
--  C O P I L O T
-- ═══════════════════════════════════════════════════════════════════

local copilot_ok, copilot = pcall(require, "copilot")
local copilot_suggestion_ok, copilot_suggestion
if copilot_ok then
	copilot_suggestion_ok, copilot_suggestion = pcall(require, "copilot.suggestion")
end

local function accept_copilot_if_visible()
	if copilot_suggestion_ok and copilot_suggestion.is_visible() and not vim.b.copilot_suggestion_hidden then
		copilot_suggestion.accept()
		return true
	end
	return false
end

local function copilot_suggestion_action(action)
	return function()
		if not copilot_suggestion_ok then
			return
		end
		if action == "next" then
			copilot_suggestion.next()
		elseif action == "prev" then
			copilot_suggestion.prev()
		elseif action == "dismiss" then
			copilot_suggestion.dismiss()
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════
--  B L I N K . C M P
-- ═══════════════════════════════════════════════════════════════════

require("blink.cmp").setup({
	signature = {
		enabled = true,
		window = {
			border = "rounded",
			show_documentation = true,
		},
	},

	snippets = { preset = "luasnip" },

	keymap = {
		preset = "none",

		["<C-space>"] = { "show_documentation", "hide_documentation" },
		["<Esc>"] = {
			function()
				require("blink.cmp").cancel()
			end,
			"fallback",
		},
		["<C-c>"] = { "cancel", "fallback" },
		["<C-e>"] = { "cancel", "fallback" },

		["<Tab>"] = { accept_copilot_if_visible, "select_and_accept", "snippet_forward", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "fallback" },

		["<Up>"] = { "select_prev", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<C-n>"] = { "select_next", "fallback" },

		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },

		["<M-]>"] = { copilot_suggestion_action("next") },
		["<M-[>"] = { copilot_suggestion_action("prev") },
	},

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
		default = { "lsp", "snippets", "buffer", "path" },
		per_filetype = {
			markdown = { "lsp", "snippets", "buffer", "path", "spell" },
			text = { "lsp", "snippets", "buffer", "path", "spell" },
			gitcommit = { "lsp", "snippets", "buffer", "path", "spell" },
		},
		providers = {
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
			},
		},
	},

	completion = {
		list = {
			selection = {
				preselect = true,
				auto_insert = true,
			},
		},
		menu = {
			auto_show = true,
			border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
			scrollbar = true,
			draw = {
				padding = { 1, 1 },
				columns = {
					{ "kind_icon", gap = 1 },
					{ "label", "label_description", gap = 1 },
					{ "kind" },
				},
			},
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 150,
			window = {
				border = "rounded",
				max_width = 80,
				max_height = 30,
			},
		},
		ghost_text = {
			enabled = false,
		},
	},

	cmdline = {
		keymap = {
			["<Esc>"] = {
				function()
					local cmp = require("blink.cmp")
					if cmp.is_active() then
						cmp.cancel()
					end
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
				end,
			},
			["<C-c>"] = { "cancel", "fallback" },
			["<Tab>"] = { "accept", "fallback" },
			["<S-Tab>"] = { "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
		},
		completion = {
			menu = { auto_show = true },
			ghost_text = { enabled = false },
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

if copilot_ok then
	copilot.setup({
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 150,
			hide_during_completion = true,
			keymap = {
				accept = false,
				next = false,
				prev = false,
				dismiss = false,
			},
		},
		panel = { enabled = true },
	})
end

vim.api.nvim_create_autocmd("User", {
	pattern = "BlinkCmpMenuOpen",
	callback = function()
		vim.b.copilot_suggestion_hidden = true
	end,
})

vim.api.nvim_create_autocmd("User", {
	pattern = "BlinkCmpMenuClose",
	callback = function()
		vim.b.copilot_suggestion_hidden = false
	end,
})

-- ═══════════════════════════════════════════════════════════════════
--  C O P I L O T   T O G G L E S   (<leader>a)
-- ═══════════════════════════════════════════════════════════════════

vim.keymap.set("n", "<leader>ac", function()
	if not copilot_ok then
		return
	end
	copilot.suggestion.enabled = not copilot.suggestion.enabled
	local status = copilot.suggestion.enabled and "enabled" or "disabled"
	vim.notify(("Copilot %s"):format(status), vim.log.levels.INFO)
end, { desc = "Toggle copilot" })

vim.keymap.set("n", "<leader>ap", function()
	if copilot_ok then
		copilot.panel.toggle()
	end
end, { desc = "Toggle copilot panel" })

vim.keymap.set("i", "<M-\\>", function()
	if copilot_suggestion_ok then
		copilot_suggestion.next()
	end
end, { desc = "Trigger copilot suggestion" })
