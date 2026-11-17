-- LSP wiring: shared capabilities, server registration and :LspHealth. Server
-- definitions live one per file in lsp/, which `vim.lsp.config` resolves by
-- name. Attach keymaps and the LSP UI plugins are separate files.

local lsp = vim.lsp
local util = require("util")

-- Servers are the lsp/<name>.lua files in the config directory. Deriving the
-- list from the files means adding a server needs no second edit here. A
-- server is only enabled when its executable exists, so an optional server
-- that is not installed stays quiet.
local servers = {}
for name, kind in vim.fs.dir(vim.fs.joinpath(vim.fn.stdpath("config"), "lsp")) do
	if kind == "file" and name:match("%.lua$") then
		servers[#servers + 1] = (name:gsub("%.lua$", ""))
	end
end
table.sort(servers)

require("lsp.attach")
require("lsp.ui")

lsp.config("*", { capabilities = util.lsp_capabilities() })

for _, name in ipairs(servers) do
	local cmd = vim.tbl_get(lsp.config[name] or {}, "cmd", 1)
	if cmd and vim.fn.executable(cmd) == 1 then
		lsp.enable(name)
	end
end

vim.api.nvim_create_user_command("LspHealth", function()
	local lines = { "LSP Health" }
	for _, name in ipairs(servers) do
		local cmd = vim.tbl_get(lsp.config[name] or {}, "cmd", 1) or name
		local path = vim.fn.exepath(cmd)
		lines[#lines + 1] = path ~= "" and ("- %s: OK (%s)"):format(name, path) or ("- %s: missing `%s`"):format(name, cmd)
	end
	local active = lsp.get_clients({ bufnr = 0 })
	if #active == 0 then
		lines[#lines + 1] = "Active: none"
	else
		local names = {}
		for _, client in ipairs(active) do
			names[#names + 1] = client.name
		end
		lines[#lines + 1] = "Active: " .. table.concat(names, ", ")
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Health" })
end, { desc = "Show LSP health details" })
