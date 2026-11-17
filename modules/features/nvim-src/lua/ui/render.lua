-- In-buffer rendering: markview for Markdown, indent guides, tag closing.

require("markview").setup({
	preview = {
		-- Markdown only; Typst and LaTeX keep their external previews.
		filetypes = { "markdown", "markdown.mdx", "quarto", "rmd" },
		icon_provider = "mini",
	},
})

require("ibl").setup({
	indent = { char = "│" },
	scope = { enabled = true, show_start = false, show_end = false },
	exclude = {
		filetypes = { "help", "markdown", "markdown.mdx", "typst", "oil", "qf" },
	},
})

require("nvim-ts-autotag").setup({})
