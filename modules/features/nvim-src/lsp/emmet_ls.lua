return {
	cmd = { "emmet-ls", "--stdio" },
	filetypes = {
		"html",
		"css",
		"scss",
		"less",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
		"astro",
		"templ",
	},
	root_markers = { "package.json", ".git" },
	init_options = { html = { options = { ["bem.enabled"] = true, ["output.indent"] = "  " } } },
}
