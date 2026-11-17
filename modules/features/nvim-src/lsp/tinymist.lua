return {
	cmd = { "tinymist" },
	filetypes = { "typst" },
	root_markers = { ".git" },
	settings = {
		tinymist = {
			exportPdf = "onType",
			formatterMode = "typstyle",
			preview = {
				scrollSync = "onSelectionChangeByCursor",
				cursor = {
					group = { { name = "primary", highlight = { background = "#ffcc00", foreground = "#000000" } } },
				},
			},
		},
	},
}
