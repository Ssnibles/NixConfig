-- Rust keys. rustaceanvim defines :RustLsp; the setup is in lang/rust.lua.

local map = vim.keymap.set

local function rustlsp(...)
	vim.cmd.RustLsp(...)
end

local function command(keys, arguments, desc)
	map("n", keys, function()
		rustlsp(arguments)
	end, { desc = desc })
end

command("<leader>rr", "runnables", "Rust runnables")
command("<leader>rt", { "testables", { background = true } }, "Rust testables")
command("<leader>rm", "expandMacro", "Rust expand macro")
command("<leader>ro", "openDocs", "Rust open docs")
command("<leader>rp", "parentModule", "Rust parent module")
command("<leader>rH", "reloadWorkspace", "Rust reload workspace")
command("<leader>re", "rebuildMacros", "Rust rebuild macros")

map({ "n", "v" }, "<leader>ra", function()
	rustlsp("codeAction")
end, { desc = "Rust code action" })

map("n", "<leader>rs", function()
	vim.lsp.stop_client(vim.lsp.get_clients({ name = "rust-analyzer", bufnr = 0 }))
	rustlsp("reloadWorkspace")
end, { desc = "Rust restart server" })
