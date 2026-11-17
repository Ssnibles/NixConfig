-- Keymaps and buffer features for attached LSP clients.
local lsp = vim.lsp
local goto_preview = require("goto-preview")
-- Switching between a source file and its header or spec.
local switch_targets = {
	c = { "h", "hpp" },
	cpp = { "hpp", "h" },
	cc = { "h", "hpp" },
	h = { "c", "cpp", "cc" },
	hpp = { "cpp", "c" },
	ts = { "spec.ts", "test.ts" },
	js = { "spec.js", "test.js" },
}
local function switch_source_header()
	if vim.fn.exists(":ClangdSwitchSourceHeader") == 2 then
		vim.cmd("ClangdSwitchSourceHeader")
		return
	end
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		return
	end
	local stem = vim.fn.fnamemodify(file, ":r")
	for _, ext in ipairs(switch_targets[vim.fn.fnamemodify(file, ":e")] or {}) do
		local path = stem .. "." .. ext
		if vim.uv.fs_stat(path) then
			vim.cmd.edit({ args = { path } })
			return
		end
	end
	pcall(vim.cmd, "b#")
end
local function show_hover_doc()
	lsp.buf.hover({
		max_width = math.floor(vim.o.columns * 0.6),
		max_height = math.floor(vim.o.lines * 0.4),
	})
end
local function attach_keymaps(bufnr)
	local function map(keys, rhs, desc)
		vim.keymap.set("n", keys, rhs, { buffer = bufnr, desc = desc })
	end
	-- Navigation
	map("gd", lsp.buf.definition, "Go to definition")
	map("gD", lsp.buf.declaration, "Go to declaration")
	map("gi", lsp.buf.implementation, "Go to implementation")
	map("grr", function()
		require("fzf-lua").lsp_references({ jump_to_single_result = true })
	end, "Find references")
	map("K", show_hover_doc, "Hover documentation")
	map("L", lsp.buf.signature_help, "Signature help")
	-- Peek
	map("gpd", goto_preview.goto_preview_definition, "Peek definition")
	map("gpD", goto_preview.goto_preview_declaration, "Peek declaration")
	map("gpi", goto_preview.goto_preview_implementation, "Peek implementation")
	map("gpr", goto_preview.goto_preview_references, "Peek references")
	map("gpt", goto_preview.goto_preview_type_definition, "Peek type definition")
	map("<leader>cp", goto_preview.close_all_win, "Close previews")
	-- Refactoring
	vim.keymap.set("n", "<leader>rn", function()
		return ":IncRename " .. vim.fn.expand("<cword>")
	end, { buffer = bufnr, desc = "Rename Symbol", expr = true })
	map("<leader>ca", lsp.buf.code_action, "Code action")
	map("<leader>cl", function()
		pcall(lsp.codelens.run)
	end, "CodeLens action")
	-- Code outline and header switching
	map("<leader>co", "<cmd>AerialToggle!<CR>", "Code Outline")
	map("<leader>ch", switch_source_header, "Switch Source/Header")
end
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
	callback = function(ev)
		attach_keymaps(ev.buf)
		local client = lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end
		if client:supports_method("textDocument/inlayHint", ev.buf) then
			pcall(lsp.inlay_hint.enable, true, { bufnr = ev.buf })
		end
		if client:supports_method("textDocument/codeLens", ev.buf) then
			pcall(lsp.codelens.enable, true, { bufnr = ev.buf })
		end
	end,
})
