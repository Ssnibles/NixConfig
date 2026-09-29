-- =============================================================================
-- markview.nvim: in-buffer Markdown rendering
-- =============================================================================
-- Loaded after the colorscheme (init.lua requires `theme` before `plugins.*`).
local ok, markview = pcall(require, "markview")
if not ok then
	return
end

markview.setup({
	preview = {
		-- Markdown only; Typst/LaTeX keep their dedicated external previews
		-- (tinymist + zathura/typst-preview) to avoid fighting over conceal.
		filetypes = { "markdown", "markdown.mdx", "quarto", "rmd" },
		icon_provider = "mini",
	},
})
