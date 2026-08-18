require("indentinator").setup({
	enabled = true,
	style = "rounded",
	draw_gap_hl = false,
	show_first_indent_level = false,
	scope = {
		enabled = true,
		treesitter = true,
		delimiters = true,
		underline_delimiters = true,
		rainbow_delimiters = true,
		background = false,
		text_highlight = false,
		range = "block",
	},
})
