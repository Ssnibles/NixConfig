-- =============================================================================
-- Completion & AI
-- =============================================================================
-- blink.cmp, luasnip, copilot (avante disabled due to auth issues)

-- blink.cmp
if pcall(require, "blink.cmp") then
	require("blink.cmp").setup({
		keymap = { preset = "super-tab" },
		cmdline = {
			keymap = {
				["<Tab>"] = { "accept", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
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
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 100,
				window = { border = "rounded" },
			},
			ghost_text = { enabled = true },
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		appearance = {
			kind_icons = {
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
			},
		},
	})
end

-- luasnip
if pcall(require, "luasnip") then
	local ok, loaders = pcall(require, "luasnip.loaders.from_vscode")
	if ok then
		loaders.lazy_load()
	end
end

-- copilot.lua (standalone, not through blink.cmp)
if pcall(require, "copilot") then
	require("copilot").setup({
		panel = {
			enabled = true,
			auto_refresh = true,
			keymap = {
				jump_next = "<C-j>",
				jump_prev = "<C-k>",
				accept = "<CR>",
				refresh = "r",
				open = "<M-CR>",
			},
			layout = { position = "bottom", ratio = 0.4 },
		},
		suggestion = {
			enabled = true,
			auto_trigger = true,
			hide_during_completion = true,
			keymap = {
				accept = "<C-Tab>",
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
		copilot_node_command = "node",
	})
end

-- copilot-chat (only if copilot is available)
local copilot_chat_ok, copilot_chat = pcall(require, "copilot.chat")
if copilot_chat_ok then
	copilot_chat.setup({
		panel = { layout = "float", auto_focus = true },
		prompts = {
			Explain = "Please explain how the selected code works:",
			Review = "Please review the selected code for potential issues:",
			Tests = "Please generate tests for the selected code:",
		},
	})

	vim.keymap.set("n", "<leader>aa", function()
		copilot_chat.open()
	end, { desc = "Copilot Chat" })
	vim.keymap.set("v", "<leader>aa", function()
		copilot_chat.open({ selection = true })
	end, { desc = "Copilot Chat (selection)" })
end

-- ── Avante AI Assistant Configuration ──────────────────────────────────────
-- Avante provides AI-powered code suggestions and chat functionality.
-- Requires copilot.lua to be authenticated first (:Copilot auth)
local avante_ok, avante = pcall(require, "avante")
if avante_ok then
	avante.setup({
		-- Provider configuration
		provider = "copilot",
		auto_suggestions_provider = "copilot",

		-- Behavior settings
		behaviour = {
			auto_suggestions = true,
			auto_set_highlight_group = true,
			auto_set_keymaps = true,
			auto_apply_diff_after_generation = false,
			support_paste_from_clipboard = true,
			minimize_diff = true,
		},

		-- Window and UI settings
		windows = {
			position = "right",
			wrap = true,
			height = 15,
			min_height = 10,
			auto_focus = false,
			border = "rounded",
		},

		-- Keymap configuration
		mappings = {
			diff = {
				our = "co",
				their = "ct",
				both = "cb",
				cursor = "cc",
				next = "]x",
				prev = "[x",
			},
			jump = {
				next = "]]",
				prev = "[[",
			},
			submit = {
				normal = "<CR>",
				insert = "<C-s>",
			},
			cancel = {
				normal = "<C-c>",
				insert = "<C-c>",
			},
		},

		-- Hints and display settings
		hints = { enabled = true },

		-- Provider-specific Copilot settings
		providers = {
			copilot = {
				endpoint = "https://api.githubcopilot.com",
				model = "gpt-4",
				proxy = nil,
				timeout = 30000,
			},
		},

		-- Debug mode (disable in production)
		debug = false,
	})
else
	vim.notify("avante.nvim not available", vim.log.levels.INFO)
end
