-- ============================================================================
-- UTILS
-- Shared helper functions available to all other Lua modules.
-- ============================================================================

local M = {}

-- map: thin wrapper around vim.keymap.set with noremap + silent defaults.
---@param mode string|string[]
---@param lhs  string
---@param rhs  string|function
---@param desc string
function M.map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

return M
