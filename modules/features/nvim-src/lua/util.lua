-- Shared helpers.
local external = require("external")
local M = {}
--- Report a toggle's new state in a consistent format.
--- @param name string Human-readable feature name
--- @param enabled boolean Whether the feature is now enabled
function M.notify_toggle(name, enabled)
	vim.notify(("%s %s"):format(name, enabled and "enabled" or "disabled"))
end
-- Helper buffers: pickers, tool panes and plugin UIs. They are never editor
-- buffers, so buffer pickers and jump targets skip them.
local helper_filetypes = {
	fzf = true,
	oil = true,
	qf = true,
	help = true,
	jj = true,
	["grug-far"] = true,
}
--- @param filetype string
--- @return boolean
function M.is_helper_ft(filetype)
	return helper_filetypes[filetype] == true or filetype:find("^grug%-far") ~= nil
end
local lsp_capabilities
--- LSP client capabilities shared by `vim.lsp.config`, nvim-jdtls and
--- rustaceanvim. Built once and copied, because clients may mutate them.
--- @return table
function M.lsp_capabilities()
	if not lsp_capabilities then
		local capabilities = require("blink.cmp").get_lsp_capabilities()
		capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
		capabilities.textDocument.semanticTokens = { requests = { range = true, full = { delta = true } } }
		lsp_capabilities = capabilities
	end
	return vim.deepcopy(lsp_capabilities)
end
local cached_c_flags
--- Include flags for the current Nix shell. Run from `nix develop`, this is what
--- clangd needs to resolve headers that live in the Nix store instead of
--- /usr/include.
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
	local cpath = ("%s:%s:%s"):format(vim.env.CPATH or "", vim.env.C_INCLUDE_PATH or "", vim.env.CPLUS_INCLUDE_PATH or "")
	for path in cpath:gmatch("[^:]+") do
		add("-I" .. path)
	end
	for flag in (vim.env.NIX_CFLAGS_COMPILE or ""):gmatch("%S+") do
		add(flag)
	end
	if external.executable("pkg-config") then
		for _, package in ipairs({
			"raylib",
			"wayland-client",
			"wlroots",
			"gl",
			"glfw3",
			"sdl2",
			"libxkbcommon",
			"libinput",
		}) do
			local result = vim.system({ "pkg-config", "--cflags", package }):wait()
			if result.code == 0 then
				for flag in result.stdout:gmatch("%S+") do
					add(flag)
				end
			end
		end
	end
	cached_c_flags = flags
	return flags
end
return M
