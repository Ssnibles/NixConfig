-- =============================================================================
-- UI Plugins Configuration
-- =============================================================================
-- Visual enhancements: which-key, gitsigns, oil, autopairs, markview, noice.
-- These plugins improve the editing experience without adding redundancy.
-- =============================================================================

local loader = require("lib.loader")

-- ── which-key (keybinding hints) ──────────────────────────────────────────
loader.setup("which-key", function(which_key)
	which_key.setup({
		win = { border = "rounded" },
		plugins = {
			marks = true,
			registers = true,
			spelling = { enabled = true, suggestions = 20 },
			presets = {
				operators = true,
				motions = true,
				text_objects = true,
				windows = true,
				nav = true,
				z = true,
				g = true,
			},
		},
	})
end)

-- ── gitsigns (git integration) ────────────────────────────────────────────
loader.setup("gitsigns", function(gitsigns)
	gitsigns.setup({
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		current_line_blame = false,
		preview_config = { border = "rounded" },
		signcolumn = true,
	})
end)

-- ── Oil (file navigation) ─────────────────────────────────────────────────
loader.setup("oil", function(oil)
	oil.setup({
		view_options = {
			show_hidden = true,
			is_always_hidden = function(name, _)
				return name == ".git"
			end,
		},
		float = { border = "rounded" },
		keymaps = {
			["<C-s>"] = false,
			["<C-h>"] = false,
			["<C-v>"] = { "actions.select", opts = { vertical = true } },
			["<C-x>"] = { "actions.select", opts = { horizontal = true } },
		},
		win_options = {
			cursorline = false,
		},
	})
end)

-- ── nvim-autopairs ────────────────────────────────────────────────────────
loader.setup("nvim-autopairs", function(autopairs)
	autopairs.setup({
		check_ts = true,
		ts_config = { lua = { "string" }, javascript = { "template_string" } },
		fast_wrap = { map = "<M-e>" },
		completion = true,
	})
end)

-- ── markview (markdown preview) ───────────────────────────────────────────
loader.setup("markview", function(markview)
	markview.setup({
		modes = { "n", "no", "c" },
		hybrid_modes = { "n", "no" },
	})
end)

-- ── noice (cmdline & notifications) ───────────────────────────────────────
loader.setup("noice", function(noice)
	noice.setup({
		notify = { enabled = false },
		messages = {
			enabled = true,
			view = "mini",
		},
		lsp = {
			progress = { enabled = false },
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
			hover = { enabled = true },
			signature = { enabled = true },
		},
		cmdline = {
			enabled = true,
			view = "cmdline",
			format = {
				cmdline = { pattern = "^:", icon = "", lang = "vim" },
				search_down = { pattern = "^/", icon = " ", lang = "regex" },
				search_up = { pattern = "^?", icon = " ", lang = "regex" },
				filter = { pattern = "^:%s*!", icon = "", lang = "bash" },
				lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },
				help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖" },
				input = { view = "cmdline_input", icon = "󰥻 " },
			},
		},
		inc_rename = { enabled = true },
		presets = {
			bottom_search = true,
			command_palette = false,
			long_message_to_split = true,
			inc_rename = true,
			lsp_doc_border = true,
		},
		routes = {
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" },
						{ find = "; after #%d+" },
						{ find = "; before #%d+" },
						{ find = "fewer lines" },
					},
				},
				view = "mini",
			},
		},
	})
end)
