-- Completion: blink.cmp, luasnip snippets, copilot.
-- Fast, modern, with a sleek Zed-inspired menu design.

-- ═══════════════════════════════════════════════════════════════════
--  L U A S N I P   (snippet engine)
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

	-- ── Keymap: Esc kills everything and exits insert mode in one press ──
	keymap = {
		preset = "none",

		-- Show / hide help manually
		["<C-space>"] = { "show_documentation", "hide_documentation" },

		-- One Esc to rule them all: cancel blink → cancel snippet → normal mode
		["<Esc>"] = {
			function(cmp)
				if cmp.is_visible() then
					cmp.cancel()
				end
				return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
			end,
		},

		-- Alternative: <C-c> forces hard exit
		["<C-c>"] = { "cancel", "fallback" },

		-- Abort completion without exiting insert mode
		["<C-e>"] = { "cancel", "fallback" },

		-- Tab: copilot ghost → accept completion → snippet forward
		["<Tab>"] = { accept_copilot_if_visible, "select_and_accept", "snippet_forward", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "fallback" },

		-- Navigation
		["<Up>"] = { "select_prev", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<C-n>"] = { "select_next", "fallback" },

		-- Scroll doc
		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },

		-- Copilot suggestion navigation
		["<M-]>"] = { copilot_suggestion_action("next") },
		["<M-[>"] = { copilot_suggestion_action("prev") },
	},

	-- ── Appearance ──────────────────────────────────────────────
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

	-- ── Sources ─────────────────────────────────────────────────
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

	-- ── Completion behaviour ────────────────────────────────────
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
			enabled = true,
		},
	},

	-- ── Cmdline completion ──────────────────────────────────────
	cmdline = {
		keymap = {
			["<Esc>"] = { "cancel", "fallback" },
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
			ghost_text = { enabled = true },
		},
	},
})

-- Workaround: blink.cmp calls write_to_dot_repeat (which uses complete())
-- even when not in Insert mode (e.g. during undo_preview after InsertLeave).
-- Guard it so it only runs when vim is actually in Insert mode.
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

-- Copilot setup (only if module is available)
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

-- ── Hide copilot ghost-text while the blink menu is visible ──

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

-- ── Copilot toggles ────────────────────────────────────────────

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
