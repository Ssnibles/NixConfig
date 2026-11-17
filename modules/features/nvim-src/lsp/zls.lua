return {
	cmd = { "zls" },
	filetypes = { "zig", "zir" },
	root_markers = { "build.zig", "zls.json", ".git" },
	settings = {
		zls = {
			enable_inlay_hints = true,
			enable_snippets = true,
			warn_style = true,
			enable_build_on_save = true,
			build_on_save_step = "check",
			enable_autofix = true,
			enable_import_embedfile = true,
			operator_completions = true,
			include_at_in_builtins = true,
		},
	},
}
