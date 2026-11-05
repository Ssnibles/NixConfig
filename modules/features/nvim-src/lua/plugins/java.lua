-- Java: nvim-jdtls drives eclipse.jdt.ls directly. Two things need it that
-- `vim.lsp.enable("jdtls")` cannot provide: the java-debug adapter for nvim-dap
-- and the JUnit runner. Nix lists the adapter and test jars in
-- `vim.g.java_debug_bundles`.

local jdtls = require("jdtls")

local root_markers = {
	".git",
	"mvnw",
	"gradlew",
	"pom.xml",
	"build.gradle",
	"build.gradle.kts",
	"settings.gradle",
	"settings.gradle.kts",
}

local settings = {
	java = {
		signatureHelp = { enabled = true },
		contentProvider = { preferred = "fernflower" },
		completion = {
			favoriteStaticMembers = {
				"org.hamcrest.MatcherAssert.assertThat",
				"org.hamcrest.Matchers.*",
				"org.hamcrest.CoreMatchers.*",
				"org.junit.jupiter.api.Assertions.*",
				"java.util.Objects.requireNonNull",
				"java.util.Objects.requireNonNullElse",
				"org.mockito.Mockito.*",
			},
			filteredTypes = { "com.sun.*", "io.micrometer.shaded.*", "java.awt.*", "jdk.*", "sun.*" },
			importOrder = { "java", "javax", "com", "org" },
		},
		sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
		codeGeneration = {
			toString = { template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}" },
			hashCodeEquals = { useJava7Objects = true },
			useBlocks = true,
		},
		configuration = { updateBuildConfiguration = "interactive" },
		saveActions = { organizeImports = false },
		format = { enabled = true },
		inlayHints = { parameterNames = { enabled = "all" } },
	},
}

-- Buffer-local extras: the shared LSP keymaps come from the LspAttach handler
-- in lsp/init.lua, and jdtls registers the `java` DAP adapter itself.
local on_attach = function(_, bufnr)
	local function map(keys, fn, desc)
		vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
	end
	map("<leader>cjo", jdtls.organize_imports, "Organise imports")
	map("<leader>cjt", jdtls.test_nearest_method, "Run nearest test")
	map("<leader>cjc", jdtls.test_class, "Run test class")
	map("<leader>cju", jdtls.update_project_config, "Update project config")
end

local function start(bufnr)
	local root = vim.fs.root(bufnr, root_markers)
	if not root then
		return
	end
	jdtls.start_or_attach({
		cmd = { "jdtls", "-data", vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.fnamemodify(root, ":t") },
		root_dir = root,
		capabilities = require("lsp.capabilities"),
		settings = settings,
		init_options = {
			bundles = vim.g.java_debug_bundles or {},
		},
		on_attach = on_attach,
	})
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserJava", { clear = true }),
	pattern = "java",
	callback = function(ev)
		start(ev.buf)
	end,
})
