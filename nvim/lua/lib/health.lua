-- lua/lib/health.lua
-- Configuration health checks for debugging

local M = {}

function M.check()
	local issues = {}

	-- Check critical plugins
	local critical = { "blink.cmp", "which-key", "gitsigns", "oil" }
	for _, plugin in ipairs(critical) do
		if not pcall(require, plugin) then
			table.insert(issues, string.format("❌ Missing: %s", plugin))
		else
			vim.log.info(string.format("✓ Loaded: %s", plugin))
		end
	end

	-- Check colorscheme
	if vim.g.colors_name ~= "vague" then
		table.insert(issues, "⚠️ Colorscheme 'vague' not active")
	end

	-- Check LSP clients
	local clients = vim.lsp.get_clients()
	if #clients == 0 then
		table.insert(issues, "⚠️ No LSP clients connected")
	end

	-- Report
	if #issues > 0 then
		vim.notify(table.concat(issues, "\n"), vim.log.levels.WARN)
	else
		vim.notify("✓ Configuration healthy", vim.log.levels.INFO)
	end
end

return M
