-- Filetypes Neovim does not detect on its own. Everything else comes from the
-- built-in table: `.qml` already maps to `qml`.
vim.filetype.add({
	extension = { mdx = "markdown.mdx" },
})
