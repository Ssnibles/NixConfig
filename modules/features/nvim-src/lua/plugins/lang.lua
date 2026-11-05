-- Language-specific configurations: Rust, C/C++, Typst

local util = require("util")

-- Rust (rustaceanvim)

vim.g.rustaceanvim = {
	server = {
		capabilities = function()
			return vim.deepcopy(require("lsp.capabilities"))
		end,
		settings = function(project_root, default_settings)
			local has_cargo = project_root and vim.uv.fs_stat(vim.fs.joinpath(project_root, "Cargo.toml")) ~= nil
			local ra = {
				["rust-analyzer"] = {
					cargo = { allFeatures = true },
					procMacro = { enable = true },
					completion = {
						autoimport = { enable = true },
						callable = { snippets = "fill_arguments" },
						postfix = { enable = true },
						termSearch = { enable = true },
					},
					checkOnSave = has_cargo,
				},
			}
			if has_cargo then
				ra["rust-analyzer"].check = { command = "clippy" }
			end
			return vim.tbl_deep_extend("force", default_settings, ra)
		end,
	},
	dap = {
		adapter = function()
			return util.lldb_dap_adapter() or false
		end,
	},
}

local function rustlsp(...)
	if vim.fn.exists(":RustLsp") == 2 then
		vim.cmd.RustLsp(...)
	end
end

local map = vim.keymap.set
map("n", "<leader>rr", function()
	rustlsp("runnables")
end, { desc = "Rust runnables" })
map("n", "<leader>rt", function()
	rustlsp({ "testables", { background = true } })
end, { desc = "Rust testables" })
map("n", "<leader>rm", function()
	rustlsp("expandMacro")
end, { desc = "Rust expand macro" })
map("n", "<leader>ro", function()
	rustlsp("openDocs")
end, { desc = "Rust open docs" })
map("n", "<leader>rp", function()
	rustlsp("parentModule")
end, { desc = "Rust parent module" })
map("n", "<leader>rH", function()
	rustlsp("reloadWorkspace")
end, { desc = "Rust reload workspace" })
map("n", "<leader>re", function()
	rustlsp("rebuildMacros")
end, { desc = "Rust rebuild macros" })
map({ "n", "v" }, "<leader>ra", function()
	rustlsp("codeAction")
end, { desc = "Rust code action" })
map("n", "<leader>rs", function()
	local ok, clients = pcall(vim.lsp.get_clients, { name = "rust-analyzer", bufnr = 0 })
	if ok and #clients > 0 then
		vim.lsp.stop_client(clients)
	end
	rustlsp("reloadWorkspace")
end, { desc = "Rust restart server" })

-- C / C++ (clangd extensions)

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
			TranslationUnit = "🅄",
			PackExpansion = "🄿",
			TemplateTypeParm = "🅃",
			TemplateTemplateParm = "🅃",
			TemplateParamObject = "🅃",
		},
	},
	memory_usage = { border = "rounded" },
	symbol_info = { border = "rounded" },
})

-- Commands from clangd_extensions, attached only to clangd buffers so the
-- shared LSP keymaps stay language neutral.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserClangd", { clear = true }),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "clangd" then
			return
		end
		local function map_buf(keys, command, desc)
			vim.keymap.set("n", keys, "<cmd>" .. command .. "<CR>", { buffer = ev.buf, desc = desc })
		end
		map_buf("<leader>cA", "ClangdAST", "AST view")
		map_buf("<leader>cT", "ClangdTypeHierarchy", "Type hierarchy")
		map_buf("<leader>cI", "ClangdSymbolInfo", "Symbol info")
		map_buf("<leader>cM", "ClangdMemoryUsage", "Clangd memory usage")
	end,
})

vim.api.nvim_create_user_command("GenerateCompileFlags", function()
	local flags = util.nix_c_flags(true)
	local file, err = io.open(vim.fn.getcwd() .. "/compile_flags.txt", "w")
	if not file then
		vim.notify("Failed: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	for _, flag in ipairs(flags) do
		file:write(flag .. "\n")
	end
	file:close()
	vim.notify("Generated compile_flags.txt")
	pcall(vim.cmd, "lsp restart")
end, { desc = "Generate compile_flags.txt from environment & pkg-config" })

-- Typst (typst-preview, Zathura synctex, and #noln / #ln surrounds)

require("typst-preview").setup({
	get_root = function(path)
		return os.getenv("TYPST_ROOT") or vim.fn.fnamemodify(path, ":h")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserTypst", { clear = true }),
	pattern = "typst",
	callback = function(ev)
		-- `san` wraps a range/selection in `#noln[…]` and `sal` wraps it in `#ln[…]`.
		vim.b[ev.buf].minisurround_config = {
			custom_surroundings = {
				n = { output = { left = "#noln[", right = "]" } },
				l = { output = { left = "#ln[", right = "]" } },
			},
		}

		vim.keymap.set("n", "<leader>tp", "<cmd>TypstPreviewToggle<CR>", {
			buffer = ev.buf,
			desc = "Toggle Typst preview",
		})

		vim.keymap.set("n", "<leader>zo", function()
			local pdf = vim.fn.expand("%:p:r") .. ".pdf"
			if vim.fn.filereadable(pdf) == 1 then
				vim.system({
					"zathura",
					"--synctex-forward=" .. vim.fn.line(".") .. ":0:" .. vim.api.nvim_buf_get_name(ev.buf),
					pdf,
				}, { detach = true })
			else
				vim.notify("PDF not found: " .. pdf, vim.log.levels.WARN)
			end
		end, { buffer = ev.buf, desc = "Open PDF in Zathura" })
	end,
})
