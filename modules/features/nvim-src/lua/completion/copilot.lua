-- Copilot: suggestions are toggled by hand, the panel is always available.

local copilot = require("copilot")
local util = require("util")

copilot.setup({ suggestion = { enabled = false }, panel = { enabled = true } })

vim.keymap.set("n", "<leader>ac", function()
	copilot.suggestion.toggle()
	util.notify_toggle("Copilot", copilot.suggestion.is_enabled())
end, { desc = "Toggle copilot" })

vim.keymap.set("n", "<leader>ap", function()
	copilot.panel.toggle()
end, { desc = "Toggle copilot panel" })
