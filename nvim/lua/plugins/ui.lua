-- Miscellaneous UI plugins — each only needs a one-liner or minimal config.

-- which-key: show pending keybind completions.
require("which-key").setup({ win = { border = "rounded" } })

-- gitsigns: git diff in the gutter + hunk navigation / staging.
require("gitsigns").setup()

-- oil: edit the filesystem like a buffer.
require("oil").setup({ view_options = { show_hidden = true } })

-- nvim-autopairs: auto-close brackets and quotes (treesitter-aware).
require("nvim-autopairs").setup({ check_ts = true })

-- markview: render markdown inline (tables, headings, code blocks, etc.).
require("markview").setup()

-- noice: replaces the cmdline UI; adds better hover / signature styling.
-- notify + messages are off because fidget / gitsigns handle those.
require("noice").setup({
	notify = { enabled = false },
	messages = { enabled = false },
	lsp = {
		progress = { enabled = false }, -- fidget handles LSP progress
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
	},
})
