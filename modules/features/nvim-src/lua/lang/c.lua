-- C and C++: clangd extensions, clangd-only maps and :GenerateCompileFlags.

local util = require("util")

require("clangd_extensions").setup({
	ast = {
		role_icons = {
			type = "🅉",
			declaration = "🄳",
			expression = "🄴",
			statement = "🅂",
			specifier = "🅂",
			["template argument"] = "🅃",
		},
		kind_icons = {
			Compound = "🄲",
			Recovery = "2",
			TranslationUnit = "🄄",
			PackExpansion = "🄿",
			TemplateTypeParm = "🅃",
			TemplateTemplateParm = "🅃",
			TemplateParamObject = "🅃",
		},
	},
	memory_usage = {},
	symbol_info = {},
})

-- clangd-only commands, attached only to clangd buffers so the shared LSP maps
-- stay language neutral.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserClangd", { clear = true }),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "clangd" then
			return
		end
		local function map(keys, command, desc)
			vim.keymap.set("n", keys, "<cmd>" .. command .. "<CR>", { buffer = ev.buf, desc = desc })
		end
		map("<leader>cA", "ClangdAST", "AST view")
		map("<leader>cT", "ClangdTypeHierarchy", "Type hierarchy")
		map("<leader>cI", "ClangdSymbolInfo", "Symbol info")
		map("<leader>cM", "ClangdMemoryUsage", "Clangd memory usage")
	end,
})

vim.api.nvim_create_user_command("GenerateCompileFlags", function()
	local path = vim.fs.joinpath(vim.fn.getcwd(), "compile_flags.txt")
	local ok, err = pcall(vim.fn.writefile, util.nix_c_flags(true), path)
	if not ok then
		vim.notify("Failed: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	vim.notify("Generated compile_flags.txt")
	pcall(vim.cmd, "lsp restart")
end, { desc = "Generate compile_flags.txt from environment and pkg-config" })
