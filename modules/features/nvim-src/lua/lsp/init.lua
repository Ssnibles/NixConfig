-- =============================================================================
-- LSP CONFIGURATION
-- =============================================================================
-- Capabilities, attach keymaps, server registration, and user commands.
-- Server definitions live in lsp/servers.lua for clean separation.
-- =============================================================================

local lsp = vim.lsp

local CONFIG = {
	border = "rounded",
	max_width_ratio = 0.6,
	max_height_ratio = 0.4,
}

-- ── Shared helpers ───────────────────────────────────────────────────

--- Check if an executable exists on PATH; return its full path or nil
local function executable(cmd)
	return vim.fn.executable(cmd) == 1 and vim.fn.exepath(cmd) or nil
end

--- Return the first executable found from a list of candidates
local function first_executable(commands)
	for _, cmd in ipairs(commands) do
		local path = executable(cmd)
		if path then
			return path
		end
	end
	return nil
end

-- Export helpers for use by other modules (lang.lua, dap.lua)
vim.g._lsp_executable = executable
vim.g._lsp_first_executable = first_executable

-- ── Capabilities ─────────────────────────────────────────────────────

local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()
capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
capabilities.textDocument.semanticTokens = { requests = { range = true, full = { delta = true } } }

-- ── LSP Keymaps (attached per buffer) ────────────────────────────────

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
	map("gr", function()
		require("fzf-lua").lsp_references({ jump_to_single_result = true })
	end, "Find references")
	map("K", show_hover_doc, "Hover documentation")
	map("L", lsp.buf.signature_help, "Signature help")

	-- Refactoring
	map("<leader>rn", function()
		return ":IncRename " .. vim.fn.expand("<cword>")
	end, "Rename Symbol", { expr = true })
	map("<leader>ca", lsp.buf.code_action, "Code action")
	map("<leader>cl", function()
		pcall(lsp.codelens.run)
	end, "CodeLens action")

	-- Format
	map("<leader>cf", function()
		local ok, conform = pcall(require, "conform")
		if ok then
			conform.format({ bufnr = bufnr, lsp_format = "fallback" })
		else
			lsp.buf.format({ async = true })
		end
	end, "Format buffer")

	-- Code outline (Aerial → fzf-lua → built-in)
	map("<leader>co", function()
		if vim.fn.exists(":AerialToggle") == 2 then
			vim.cmd("AerialToggle!")
		else
			local fzf_ok, fzf = pcall(require, "fzf-lua")
			if fzf_ok then
				fzf.lsp_document_symbols()
			else
				lsp.buf.document_symbol()
			end
		end
	end, "Code Outline")

	-- Switch source/header
	map("<leader>ch", function()
		if vim.fn.exists(":ClangdSwitchSourceHeader") == 2 then
			vim.cmd("ClangdSwitchSourceHeader")
			return
		end
		local file = vim.api.nvim_buf_get_name(0)
		if file == "" then return end
		local ext = vim.fn.fnamemodify(file, ":e")
		local stem = vim.fn.fnamemodify(file, ":r")
		local alts = {
			c = { "h", "hpp" }, cpp = { "hpp", "h" }, cc = { "h", "hpp" },
			h = { "c", "cpp", "cc" }, hpp = { "cpp", "c" },
			ts = { "spec.ts", "test.ts" }, js = { "spec.js", "test.js" },
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
			local fzf_ok, fzf = pcall(require, "fzf-lua")
			if fzf_ok then
				fzf.lsp_document_symbols()
			else
				lsp.buf.document_symbol()
			end
		end
	end, "Symbol Info")

	-- Memory / status
	map("<leader>cM", function()
		if vim.fn.exists(":ClangdMemoryUsage") == 2 then
			vim.cmd("ClangdMemoryUsage")
		else
			vim.cmd("LspInfo")
		end
	end, "LSP Memory/Status")

	-- Inlay hints
	if lsp.inlay_hint then
		pcall(lsp.inlay_hint.enable, true, { bufnr = bufnr })
	end
end

vim.g.attach_lsp_keymaps = attach_lsp_keymaps

-- ── Global LSP defaults ─────────────────────────────────────────────

lsp.config("*", {
	capabilities = capabilities,
	flags = { debounce_text_changes = 150 },
	on_attach = function(_, bufnr)
		attach_lsp_keymaps(bufnr)
	end,
})

-- ── Server registration ──────────────────────────────────────────────

local managed_servers = {}

--- Register and enable an LSP server if its binary exists on PATH
local function register_server(name, config)
	if type(config) == "function" then
		config = config()
	end
	config = config or {}

	local cmd = config.cmd
	local exe = config.exe
	if not exe then
		if type(cmd) == "table" and cmd[1] then
			exe = cmd[1]
		elseif type(cmd) == "string" then
			exe = cmd
		else
			exe = name
		end
	end

	local lsp_opts = vim.deepcopy(config)
	lsp_opts.exe = nil

	local is_exec = vim.fn.executable(exe) == 1
	table.insert(managed_servers, { name = name, cmd = exe, active = is_exec })

	if is_exec then
		if next(lsp_opts) ~= nil then
			lsp.config(name, lsp_opts)
		end
		lsp.enable(name)
	elseif config.warn_if_missing then
		vim.notify(("Skipped %s LSP: `%s` not found"):format(name, exe), vim.log.levels.WARN)
	end
end

vim.g.register_lsp_server = register_server

-- Load and register all servers from the data table
local servers = require("lsp.servers")
for name, config in pairs(servers) do
	register_server(name, config)
end

-- ── SmartRename command ──────────────────────────────────────────────

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
	if not ok then return end
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
			format_item = function(item) return item.label end,
		}, function(choice)
			if choice then choice.action() end
		end)
	end
end, { desc = "Context-aware rename and replace" })

-- ── LspHealth command ────────────────────────────────────────────────

vim.api.nvim_create_user_command("LspHealth", function()
	local lines = { "LSP Health" }
	for _, server in ipairs(managed_servers) do
		local path = vim.fn.exepath(server.cmd)
		lines[#lines + 1] = path ~= ""
			and ("- %s: OK (%s)"):format(server.name, path)
			or ("- %s: missing `%s`"):format(server.name, server.cmd)
	end
	local active = lsp.get_clients({ bufnr = 0 })
	if #active > 0 then
		local names = {}
		for _, c in ipairs(active) do names[#names + 1] = c.name end
		lines[#lines + 1] = "Active: " .. table.concat(names, ", ")
	else
		lines[#lines + 1] = "Active: none"
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Health" })
end, { desc = "Show LSP health details" })

-- ── Third-party plugin setups ────────────────────────────────────────

-- Typst preview
local ok_tp, tp = pcall(require, "typst-preview")
if ok_tp then
	tp.setup({
		get_root = function(path)
			return os.getenv("TYPST_ROOT") or vim.fn.fnamemodify(path, ":h")
		end,
	})
end

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

-- Fidget (notifications + LSP progress)
local ok_fidget, fidget = pcall(require, "fidget")
if ok_fidget then
	fidget.setup({ notification = { override_vim_notify = true } })
end

-- Inc-rename
local ok_ir, ir = pcall(require, "inc_rename")
if ok_ir then
	ir.setup({})
end

-- Roslyn (C#)
local ok_roslyn, roslyn = pcall(require, "roslyn")
if ok_roslyn then
	roslyn.setup({ filewatching = "roslyn" })
end
