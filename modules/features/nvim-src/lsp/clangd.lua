-- clangd: Nix has no system headers, so the include paths from the current
-- `nix develop` shell are injected as fallback flags during initialisation.

local util = require("util")

return {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=llvm",
		"--query-driver=/**/*",
		"--all-scopes-completion",
		"--suggest-missing-includes",
		"--cross-file-rename",
	},
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
	root_markers = {
		".clangd",
		".clang-format",
		".clang-tidy",
		"compile_commands.json",
		"compile_flags.txt",
		"CMakeLists.txt",
		"Makefile",
		"meson.build",
		"build.ninja",
		"flake.nix",
		".git",
	},
	-- Merged on top of the shared capabilities from `vim.lsp.config("*")`.
	capabilities = { offsetEncoding = { "utf-16" } },
	-- `on_new_config` is an lspconfig-era field that native `vim.lsp.config`
	-- ignores; `before_init` receives the initialise params just before they are
	-- sent, which is where the Nix flags belong.
	before_init = function(params)
		params.initializationOptions = params.initializationOptions or {}
		params.initializationOptions.fallbackFlags = util.nix_c_flags()
	end,
}
