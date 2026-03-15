-- Miscellaneous UI plugins.

-- ── which-key ─────────────────────────────────────────────────────────────
require("which-key").setup({ win = { border = "rounded" } })

-- ── gitsigns ──────────────────────────────────────────────────────────────
require("gitsigns").setup({
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "▎" },
		untracked = { text = "▎" },
	},
	-- Inline blame at end of line (toggle with <leader>gb)
	current_line_blame = false,
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "eol",
		delay = 600,
		ignore_whitespace = true,
	},
	current_line_blame_formatter = " <author>, <author_time:%Y-%m-%d> · <summary>",
	preview_config = { border = "rounded" },
})

-- ── oil ───────────────────────────────────────────────────────────────────
require("oil").setup({
	view_options = {
		show_hidden = true,
		is_always_hidden = function(name, _)
			-- hide .git directory clutter but keep dotfiles
			return name == ".git"
		end,
	},
	float = { border = "rounded" },
	keymaps = {
		["<C-s>"] = false, -- don't steal our save binding
		["<C-h>"] = false, -- don't steal our window nav binding
		["<C-v>"] = { "actions.select", opts = { vertical = true } },
		["<C-x>"] = { "actions.select", opts = { horizontal = true } },
	},
})

-- ── nvim-autopairs ────────────────────────────────────────────────────────
require("nvim-autopairs").setup({
	check_ts = true,
	ts_config = { lua = { "string" }, javascript = { "template_string" } },
	fast_wrap = { map = "<M-e>" }, -- <Alt-e> to fast-wrap the next word
})

-- ── markview ──────────────────────────────────────────────────────────────
require("markview").setup()

-- ── noice ─────────────────────────────────────────────────────────────────
require("noice").setup({
	notify = { enabled = false }, -- fidget handles notifications
	messages = { enabled = false }, -- keep standard message area
	lsp = {
		progress = { enabled = false }, -- fidget handles LSP progress
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
		hover = { enabled = true },
		signature = { enabled = true },
	},
	presets = {
		bottom_search = true, -- use a classic bottom cmdline for search
		command_palette = false,
		long_message_to_split = true, -- long messages go to a split
		inc_rename = true, -- shows the rename UI inline
	},
})
