-- Shared helpers used across the configuration.

local M = {}

--- Full path to `cmd` if it is executable, otherwise nil.
--- @param cmd string
--- @return string|nil
function M.executable(cmd)
	return vim.fn.executable(cmd) == 1 and vim.fn.exepath(cmd) or nil
end

--- Return the first executable found from a list of candidates.
--- @param commands string[]
--- @return string|nil
function M.first_executable(commands)
	for _, cmd in ipairs(commands) do
		local path = M.executable(cmd)
		if path then
			return path
		end
	end
	return nil
end

--- Path to the first available LLDB-family debug adapter, if any.
--- @return string|nil
function M.find_debug_adapter()
	return M.first_executable({ "codelldb", "lldb-dap", "lldb-vscode" })
end

--- Build a nvim-dap adapter definition for the available LLDB binary.
--- @return table|nil
function M.lldb_dap_adapter()
	local lldb = M.find_debug_adapter()
	if not lldb then
		return nil
	end
	if lldb:match("codelldb$") then
		return {
			type = "server",
			host = "127.0.0.1",
			port = "${port}",
			executable = { command = lldb, args = { "--port", "${port}" } },
		}
	end
	return { type = "executable", command = lldb, name = "lldb" }
end

--- Report a toggle's new state in a consistent format.
--- @param name string Human-readable feature name
--- @param enabled boolean Whether the feature is now enabled
function M.notify_toggle(name, enabled)
	vim.notify(("%s %s"):format(name, enabled and "enabled" or "disabled"))
end

return M
