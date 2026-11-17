return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".stylua.toml", "flake.nix", ".git" },
	settings = {
		Lua = {
			hint = { enable = true, arrayIndex = "Disable" },
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			completion = {
				callSnippet = "Replace",
				keywordSnippet = "Replace",
				displayContext = 5,
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					vim.fn.stdpath("config"),
				},
			},
			telemetry = { enable = false },
		},
	},
}
