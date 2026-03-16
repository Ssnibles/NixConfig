-- =============================================================================
-- Completion and AI Configuration
-- =============================================================================
-- blink.cmp setup for async completion.
-- GitHub Copilot runs as a separate plugin (not through blink.cmp sources).
-- Highlight overrides are centralized in lib/highlights.lua
-- ── blink.cmp Configuration ────────────────────────────────────────────────
require("blink.cmp").setup({
	-- Use Super-Tab style keybindings for completion navigation
	keymap = { preset = "super-tab" },
	-- Command-line completion settings
	cmdline = {
		keymap = {
			["<Tab>"] = { "accept", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
		},
		completion = {
			menu = { auto_show = true },
			ghost_text = { enabled = true },
		},
	},
	-- Completion menu and documentation window settings
	completion = {
		menu = {
			auto_show = true,
			border = "rounded",
			winhighlight = "Normal:BlinkMenuNormal,FloatBorder:BlinkMenuBorder,CursorLine:BlinkMenuSel,Search:None",
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 100,
			window = {
				border = "rounded",
				winhighlight = "Normal:BlinkMenuNormal,FloatBorder:BlinkMenuBorder",
			},
		},
		ghost_text = { enabled = true },
	},
	-- Completion sources (copilot handled separately via copilot.lua plugin)
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
	-- Appearance settings
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
-- Load VS Code-format snippets from friendly-snippets
require("luasnip.loaders.from_vscode").lazy_load()
-- ── GitHub Copilot Configuration ───────────────────────────────────────────
-- Standalone copilot.lua plugin for inline ghost text suggestions
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
		layout = {
			position = "bottom",
			ratio = 0.4,
		},
	},
	suggestion = {
		enabled = true,
		auto_trigger = true,
		hide_during_completion = true,
		keymap = {
			accept = "<C-Tab>",
			accept_word = false,
			accept_line = false,
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
		hgcommit = false,
		svn = false,
		cvs = false,
		["."] = false,
	},
	copilot_node_command = "node",
	server_opts_overrides = {},
})
-- ── Avante AI Assistant Configuration ──────────────────────────────────────
require("avante").setup({
	-- Provider configuration (GitHub Copilot)
	provider = "copilot",
	auto_suggestions_provider = "copilot",
	-- Behavior settings
	behaviour = {
		auto_set_keymaps = true,
		auto_set_highlight_group = true,
		auto_jump_to_result_window = false,
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
	-- Provider-specific Copilot settings (NEW API STRUCTURE)
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
-- ── Copilot Chat Integration ───────────────────────────────────────────────
local copilot_chat_ok, copilot_chat = pcall(require, "copilot.chat")
if copilot_chat_ok then
	copilot_chat.setup({
		panel = {
			layout = "float",
			auto_focus = true,
		},
		prompts = {
			Explain = "Please explain how the selected code works:",
			Review = "Please review the selected code for potential issues:",
			Tests = "Please generate tests for the selected code:",
			Optimize = "Please optimize the selected code for performance:",
			Docs = "Please generate documentation for the selected code:",
			Fix = "Please fix any issues in the selected code:",
		},
	})
	-- Keymaps for Copilot Chat
	vim.keymap.set("n", "<leader>aa", function()
		copilot_chat.open()
	end, { desc = "Copilot Chat (Open)" })
	vim.keymap.set("v", "<leader>aa", function()
		copilot_chat.open({ selection = true })
	end, { desc = "Copilot Chat (Selection)" })
	vim.keymap.set("n", "<leader>ae", function()
		copilot_chat.prompt("Explain")
	end, { desc = "Copilot: Explain Code" })
	vim.keymap.set("v", "<leader>ae", function()
		copilot_chat.prompt("Explain", { selection = true })
	end, { desc = "Copilot: Explain Selection" })
	vim.keymap.set("v", "<leader>ar", function()
		copilot_chat.prompt("Review", { selection = true })
	end, { desc = "Copilot: Review Code" })
	vim.keymap.set("v", "<leader>at", function()
		copilot_chat.prompt("Tests", { selection = true })
	end, { desc = "Copilot: Generate Tests" })
end
