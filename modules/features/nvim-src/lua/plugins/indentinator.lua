require("indentinator").setup({
	draw_gap_hl = false,
	show_first_indent_level = false,
	style = "rounded",
	scope = {
		enabled = true,
		treesitter = true,
		delimiters = true,
		background = false,
		text_highlight = false,
		range = "block",
	},
})
