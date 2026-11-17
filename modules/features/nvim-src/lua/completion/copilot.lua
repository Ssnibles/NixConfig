-- Copilot: lazy setup on first use. The client starts only when the toggle or
-- panel is first requested, and the supported command module does the global
-- enable and disable work.

local util = require("util")

local M = {}
local started = false
local enabled = false

local function start()
	if not started then
		require("copilot").setup({ suggestion = { enabled = true }, panel = { enabled = true } })
		started = true
		enabled = true
	elseif not enabled then
		require("copilot.command").enable()
		enabled = true
	end
end

function M.toggle()
	if not started then
		start()
	else
		local command = require("copilot.command")
		if enabled then
			command.disable()
			enabled = false
		else
			command.enable()
			enabled = true
		end
	end
	util.notify_toggle("Copilot", enabled)
end

function M.panel()
	start()
	local ready = vim.wait(1500, function()
		return #vim.lsp.get_clients({ name = "copilot" }) > 0
	end, 50)
	if not ready then
		vim.notify("Copilot client is not ready", vim.log.levels.WARN)
		return
	end
	require("copilot.panel").toggle()
end

vim.keymap.set("n", "<leader>ac", M.toggle, { desc = "Toggle copilot" })
vim.keymap.set("n", "<leader>ap", M.panel, { desc = "Toggle copilot panel" })

return M
