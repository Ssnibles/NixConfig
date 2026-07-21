local function first_executable(commands)
	for _, cmd in ipairs(commands) do
		if vim.fn.executable(cmd) == 1 then
			return vim.fn.exepath(cmd)
		end
	end
	return nil
end

vim.g.rustaceanvim = {
	server = {
		settings = function(project_root, default_settings)
			local has_cargo_toml = project_root ~= nil
				and vim.uv.fs_stat(vim.fs.joinpath(project_root, "Cargo.toml")) ~= nil
			local ra_settings = {
				["rust-analyzer"] = {
					cargo = { allFeatures = true },
					procMacro = { enable = true },
					completion = { autoimport = { enable = true } },
				},
			}
			if has_cargo_toml then
				ra_settings["rust-analyzer"].checkOnSave = true
				ra_settings["rust-analyzer"].check = { command = "clippy" }
			else
				ra_settings["rust-analyzer"].checkOnSave = false
			end
			return vim.tbl_deep_extend("force", default_settings, ra_settings)
		end,
	},
	dap = {
		adapter = function(_, config)
			local codelldb = first_executable({ "codelldb", "lldb-dap", "lldb-vscode" })
			if not codelldb then return false end
			if codelldb:match("codelldb$") then
				return {
					type = "server",
					port = "${port}",
					host = "127.0.0.1",
					executable = { command = codelldb, args = { "--port", "${port}" } },
				}
			else
				return { type = "executable", command = codelldb, name = "lldb" }
			end
		end,
	},
}

vim.keymap.set("n", "<leader>rr", function() vim.cmd.RustLsp("runnables") end, { desc = "Rust runnables" })
vim.keymap.set("n", "<leader>rt", function() vim.cmd.RustLsp({ "testables", { background = true } }) end, { desc = "Rust testables" })
vim.keymap.set("n", "<leader>rm", function() vim.cmd.RustLsp("expandMacro") end, { desc = "Rust expand macro" })
vim.keymap.set("n", "<leader>ro", function() vim.cmd.RustLsp("openDocs") end, { desc = "Rust open docs" })
vim.keymap.set("n", "<leader>rp", function() vim.cmd.RustLsp("parentModule") end, { desc = "Rust parent module" })
vim.keymap.set("n", "<leader>rH", function() vim.cmd.RustLsp("reloadWorkspace") end, { desc = "Rust reload workspace" })
vim.keymap.set("n", "<leader>re", function() vim.cmd.RustLsp("rebuildMacros") end, { desc = "Rust rebuild macros" })
vim.keymap.set({ "n", "v" }, "<leader>ra", function() vim.cmd.RustLsp("codeAction") end, { desc = "Rust code action" })
vim.keymap.set("n", "<leader>rs", function()
	local ok, clients = pcall(vim.lsp.get_clients, { name = "rust-analyzer", bufnr = 0 })
	if ok and #clients > 0 then vim.lsp.stop_client(clients) end
	vim.cmd.RustLsp("reloadWorkspace")
end, { desc = "Rust restart server" })
