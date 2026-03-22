-- =============================================================================
-- Plugin Loader Utility
-- =============================================================================
-- Defensive plugin loading with consistent error handling and lazy loading
-- support. Replaces the need for lazy.nvim in Nix-managed environments.
-- =============================================================================

local M = {}

--- Safely require a module, returning nil if unavailable
---@param module_name string
---@return table|nil
function M.require(module_name)
	local ok, mod = pcall(require, module_name)
	if not ok then
		return nil
	end
	return mod
end

--- Safely require and setup a plugin with optional config
---@param module_name string
---@param setup_fn? fun(mod: table)
---@return boolean success
function M.setup(module_name, setup_fn)
	local mod = M.require(module_name)
	if not mod then
		return false
	end
	if setup_fn then
		local ok, err = pcall(setup_fn, mod)
		if not ok then
			vim.notify("Failed to setup " .. module_name .. ": " .. tostring(err), vim.log.levels.ERROR)
			return false
		end
	end
	return true
end

--- Require with event-based lazy loading
---@param module_name string
---@param events string|string[]
---@param setup_fn? fun(mod: table)
function M.lazy(module_name, events, setup_fn)
	local loaded = false
	local mod = nil
	local function load()
		if loaded then
			return
		end
		loaded = true
		mod = M.require(module_name)
		if mod and setup_fn then
			pcall(setup_fn, mod)
		end
	end
	if type(events) == "string" then
		events = { events }
	end

	vim.api.nvim_create_autocmd(events, {
		callback = load,
		once = true,
		desc = "Lazy load: " .. module_name,
	})

	return setmetatable({}, {
		__index = function(_, key)
			if not loaded then
				load()
			end
			return mod and mod[key]
		end,
	})
end
return M
