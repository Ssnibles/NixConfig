-- Optional external commands, all installed by Nix. Each is looked up at
-- runtime so a missing tool disables one feature instead of breaking startup.
-- This is the only file that names external binaries.
local M = {}
--- Full path to `cmd` when it is executable, otherwise nil.
--- @param cmd string
--- @return string|nil
function M.executable(cmd)
	return vim.fn.executable(cmd) == 1 and vim.fn.exepath(cmd) or nil
end
--- @return string|nil
function M.wl_paste()
	return M.executable("wl-paste")
end
--- @return string|nil
function M.jjui()
	return M.executable("jjui")
end
--- @return string|nil
function M.zathura()
	return M.executable("zathura")
end
--- @return string|nil
function M.debugpy()
	return M.executable("debugpy-adapter")
end
--- @return string|nil
function M.delve()
	return M.executable("dlv")
end
--- @return string|nil
function M.lldb()
	return M.executable("lldb-dap")
end
--- @return string|nil
function M.js_debug()
	return M.executable("js-debug")
end
--- nvim-dap adapter for the LLDB binary Nix installs.
--- @return table|nil
function M.lldb_dap_adapter()
	local lldb = M.lldb()
	if not lldb then
		return nil
	end
	return { type = "executable", command = lldb, name = "lldb" }
end
return M
