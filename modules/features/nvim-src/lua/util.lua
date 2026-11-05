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

--- Filetypes of helper buffers: pickers, tool panes and dev-plugin UIs. They
--- are never editor buffers, so buffer pickers and jump targets skip them.
local helper_filetypes = {
	fzf = true,
	oil = true,
	qf = true,
	help = true,
	jj = true,
	startinator = true,
	sshinator = true,
	["grug-far"] = true,
}

--- True when `filetype` belongs to a helper buffer. Callers that care about
--- terminal buffers check `buftype` as well.
--- @param filetype string
--- @return boolean
function M.is_helper_ft(filetype)
	return helper_filetypes[filetype] == true or filetype:find("^grug%-far") ~= nil
end

local cached_c_flags = nil

--- C compiler include flags for the current Nix shell, cached between calls.
--- Run from a `nix develop` shell, this is what clangd needs to resolve
--- headers that live in the Nix store instead of /usr/include.
--- @param refresh boolean? Recompute even if cached
--- @return string[]
function M.nix_c_flags(refresh)
	if cached_c_flags and not refresh then
		return cached_c_flags
	end

	local flags = { "-std=c11", "-Wall", "-Wextra" }
	local seen = { ["-std=c11"] = true, ["-Wall"] = true, ["-Wextra"] = true }

	local function add(flag)
		if flag and flag ~= "" and not seen[flag] then
			seen[flag] = true
			flags[#flags + 1] = flag
		end
	end

	local cpath = (vim.env.CPATH or "")
		.. ":"
		.. (vim.env.C_INCLUDE_PATH or "")
		.. ":"
		.. (vim.env.CPLUS_INCLUDE_PATH or "")
	for path in cpath:gmatch("[^:]+") do
		if path ~= "" then
			add("-I" .. path)
		end
	end

	for flag in (vim.env.NIX_CFLAGS_COMPILE or ""):gmatch("%S+") do
		add(flag)
	end

	if vim.fn.executable("pkg-config") == 1 then
		local out = vim.fn.system(
			"for p in raylib wayland-client wlroots gl glfw3 sdl2 libxkbcommon libinput; do pkg-config --cflags $p 2>/dev/null; done"
		)
		for flag in out:gmatch("%S+") do
			add(flag)
		end
	end

	cached_c_flags = flags
	return flags
end

return M
