-- LSP CONFIGURATION
-- Capabilities, attach keymaps, server registration, and user commands.
-- Server definitions live in lsp/servers.lua for clean separation.

local lsp = vim.lsp

local CONFIG = {
	border = "rounded",
	max_width_ratio = 0.6,
	max_height_ratio = 0.4,
}

-- Capabilities

local capabilities = require("lsp.capabilities")

-- goto-preview (peek definitions/references in a floating window)
local ok_gp, goto_preview = pcall(require, "goto-preview")
if not ok_gp then
	goto_preview = nil
end

-- LSP Keymaps (attached per buffer)

local function show_hover_doc()
	lsp.buf.hover({
		border = CONFIG.border,
		max_width = math.floor(vim.o.columns * CONFIG.max_width_ratio),
		max_height = math.floor(vim.o.lines * CONFIG.max_height_ratio),
	})
end

local function attach_lsp_keymaps(bufnr)
	if vim.b[bufnr]._lsp_keymaps_attached then
		return
	end
	vim.b[bufnr]._lsp_keymaps_attached = true

	local map = function(keys, fn, desc, extra)
		vim.keymap.set("n", keys, fn, vim.tbl_extend("force", { buffer = bufnr, desc = desc }, extra or {}))
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

	-- Peek (goto-preview)
	if goto_preview then
		map("gpd", goto_preview.goto_preview_definition, "Peek definition")
		map("gpD", goto_preview.goto_preview_declaration, "Peek declaration")
		map("gpi", goto_preview.goto_preview_implementation, "Peek implementation")
		map("gpr", goto_preview.goto_preview_references, "Peek references")
		map("gpt", goto_preview.goto_preview_type_definition, "Peek type definition")
		map("<leader>cp", goto_preview.close_all_win, "Close previews")
	end

	-- Refactoring
	map("<leader>rn", function()
		return ":IncRename " .. vim.fn.expand("<cword>")
	end, "Rename Symbol", { expr = true })
	map("<leader>ca", lsp.buf.code_action, "Code action")
	map("<leader>cl", function()
		pcall(lsp.codelens.run)
	end, "CodeLens action")

	-- Code outline
	map("<leader>co", "<cmd>AerialToggle!<CR>", "Code Outline")

	-- Switch source/header
	map("<leader>ch", function()
		if vim.fn.exists(":ClangdSwitchSourceHeader") == 2 then
			vim.cmd("ClangdSwitchSourceHeader")
			return
		end
		local file = vim.api.nvim_buf_get_name(0)
		if file == "" then
			return
		end
		local ext = vim.fn.fnamemodify(file, ":e")
		local stem = vim.fn.fnamemodify(file, ":r")
		local alts = {
			c = { "h", "hpp" },
			cpp = { "hpp", "h" },
			cc = { "h", "hpp" },
			h = { "c", "cpp", "cc" },
			hpp = { "cpp", "c" },
			ts = { "spec.ts", "test.ts" },
			js = { "spec.js", "test.js" },
		}
		for _, alt in ipairs(alts[ext] or {}) do
			local path = stem .. "." .. alt
			if vim.uv.fs_stat(path) then
				vim.cmd("edit " .. vim.fn.fnameescape(path))
				return
			end
		end
		pcall(vim.cmd, "b#")
	end, "Switch Source/Header")

	-- AST view
	map("<leader>cA", function()
		if vim.fn.exists(":ClangdAST") == 2 then
			vim.cmd("ClangdAST")
		elseif vim.fn.exists(":InspectTree") == 2 then
			vim.cmd("InspectTree")
		end
	end, "View AST")

	-- Type hierarchy
	map("<leader>cT", function()
		if vim.fn.exists(":ClangdTypeHierarchy") == 2 then
			vim.cmd("ClangdTypeHierarchy")
		elseif lsp.buf.type_hierarchy then
			lsp.buf.type_hierarchy()
		end
	end, "Type Hierarchy")

	-- Symbol info
	map("<leader>cI", function()
		if vim.fn.exists(":ClangdSymbolInfo") == 2 then
			vim.cmd("ClangdSymbolInfo")
		else
			require("fzf-lua").lsp_document_symbols()
		end
	end, "Symbol Info")

	-- Memory / status
	map("<leader>cM", function()
		if vim.fn.exists(":ClangdMemoryUsage") == 2 then
			vim.cmd("ClangdMemoryUsage")
		else
			vim.cmd("checkhealth vim.lsp")
		end
	end, "LSP Memory/Status")
end

-- LSP Attach Autocommand

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
	callback = function(args)
		attach_lsp_keymaps(args.buf)

		local client = lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end

		if lsp.inlay_hint and client:supports_method("textDocument/inlayHint", args.buf) then
			pcall(lsp.inlay_hint.enable, true, { bufnr = args.buf })
		end

		if client:supports_method("textDocument/codeLens", args.buf) and lsp.codelens.enable then
			-- vim.lsp.codelens.refresh() was removed in 0.13; enable() is the API now.
			pcall(lsp.codelens.enable, true, { bufnr = args.buf })
		end
	end,
})

-- Global LSP defaults & server registration

lsp.config("*", { capabilities = capabilities })

local managed_servers = {}

for name, cfg in pairs(require("lsp.servers")) do
	cfg = type(cfg) == "function" and cfg() or cfg
	local exe = (cfg.cmd and cfg.cmd[1]) or name
	local active = vim.fn.executable(exe) == 1
	managed_servers[#managed_servers + 1] = { name = name, cmd = exe, active = active }
	if active then
		lsp.config(name, cfg)
		lsp.enable(name)
	end
end

-- SmartRename command

local function supports_lsp_rename(bufnr)
	for _, client in ipairs(lsp.get_clients({ bufnr = bufnr })) do
		if client:supports_method("textDocument/rename", bufnr) then
			return true
		end
	end
	return false
end

local function prompt_lsp_rename()
	local name = vim.fn.expand("<cword>")
	if name == "" then
		lsp.buf.rename()
		return
	end
	vim.ui.input({ prompt = "Rename symbol to: ", default = name }, function(new)
		if new and new ~= "" and new ~= name then
			lsp.buf.rename(new)
		end
	end)
end

local function escape_rg(text)
	return text:gsub("([%(%)%.%+%-%*%?%[%]%^%$%{%}%|\\])", "\\%1")
end

local function open_grug_far(prefills)
	local ok, grug = pcall(require, "grug-far")
	if not ok then
		return
	end
	local instance = grug.open({ prefills = prefills })
	if instance and type(instance.when_ready) == "function" and type(instance.goto_input) == "function" then
		instance:when_ready(function()
			instance:goto_input("replacement")
		end)
	end
end

vim.api.nvim_create_user_command("SmartRename", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local word = vim.fn.expand("<cword>")
	local choices = {}

	if supports_lsp_rename(bufnr) then
		choices[#choices + 1] = { label = "LSP symbol rename (recommended)", action = prompt_lsp_rename }
	end
	if word ~= "" then
		choices[#choices + 1] = {
			label = "Project replace word (literal)",
			action = function()
				open_grug_far({ search = word, flags = "--fixed-strings --word-regexp" })
			end,
		}
		choices[#choices + 1] = {
			label = "Project replace regex",
			action = function()
				open_grug_far({ search = ("\\b%s\\b"):format(escape_rg(word)) })
			end,
		}
	end

	if #choices == 0 then
		vim.notify("No rename target: place cursor on a word", vim.log.levels.WARN)
	elseif #choices == 1 then
		choices[1].action()
	else
		vim.ui.select(choices, {
			prompt = "Rename/replace mode:",
			format_item = function(item)
				return item.label
			end,
		}, function(choice)
			if choice then
				choice.action()
			end
		end)
	end
end, { desc = "Context-aware rename and replace" })

-- LspHealth command

vim.api.nvim_create_user_command("LspHealth", function()
	local lines = { "LSP Health" }
	for _, server in ipairs(managed_servers) do
		local path = vim.fn.exepath(server.cmd)
		lines[#lines + 1] = path ~= "" and ("- %s: OK (%s)"):format(server.name, path)
			or ("- %s: missing `%s`"):format(server.name, server.cmd)
	end
	local active = lsp.get_clients({ bufnr = 0 })
	if #active > 0 then
		local names = {}
		for _, c in ipairs(active) do
			names[#names + 1] = c.name
		end
		lines[#lines + 1] = "Active: " .. table.concat(names, ", ")
	else
		lines[#lines + 1] = "Active: none"
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Health" })
end, { desc = "Show LSP health details" })

-- Third-party LSP UI plugins

-- Aerial (code outline)
local ok_aerial, aerial = pcall(require, "aerial")
if ok_aerial then
	aerial.setup({
		on_attach = function(bufnr)
			vim.keymap.set("n", "[a", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Previous symbol (Aerial)" })
			vim.keymap.set("n", "]a", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next symbol (Aerial)" })
		end,
		show_guides = true,
		layout = { max_width = { 40, 0.2 }, min_width = 30, default_direction = "prefer_right" },
		filter_kind = false,
		highlight_on_hover = true,
		autojump = false,
	})
end

-- Inc-rename
local ok_ir, ir = pcall(require, "inc_rename")
if ok_ir then
	ir.setup({})
end

-- goto-preview
if goto_preview then
	goto_preview.setup({
		references = { provider = "fzf_lua" },
	})
end
