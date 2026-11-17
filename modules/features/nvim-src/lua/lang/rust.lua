-- Rust: rustaceanvim. The table is read by the plugin when it loads, so it is
-- set during init.

local external = require("external")
local util = require("util")

vim.g.rustaceanvim = {
	server = {
		capabilities = function()
			return util.lsp_capabilities()
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
			return external.lldb_dap_adapter() or false
		end,
	},
}
