-- =============================================================================
-- Optimized Plugin Loader Utility
-- =============================================================================
-- Handles safe requirements, setup orchestration, and performance tracking.
-- =============================================================================
local M = {}

-- Performance and health metrics
M.stats = {
	loaded = {},
	failed = {},
	start_time = vim.uv.hrtime(),
}

--- Logs a formatted error to the notification system
---@param msg string
local function log_err(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "Plugin Loader" })
end

--- Safely require a module with performance tracking
---@param name string
---@return table|nil
function M.require(name)
	local start = vim.uv.hrtime()
	local ok, mod = pcall(require, name)
	local duration = (vim.uv.hrtime() - start) / 1e6 -- ms

	if ok then
		M.stats.loaded[name] = duration
		return mod
	else
		M.stats.failed[name] = mod
		return nil
	end
end

--- Orchestrates the setup of a plugin
---@param name string The module name to require
---@param config? function|table Configuration function (receives module) or table (passed to .setup())
function M.setup(name, config)
	local mod = M.require(name)
	if not mod then
		return false
	end

	local ok, err
	if type(config) == "function" then
		ok, err = pcall(config, mod)
	elseif type(mod.setup) == "function" then
		ok, err = pcall(mod.setup, config or {})
	end

	if not ok and err then
		log_err(string.format("Failed to setup %s: %s", name, err))
		return false
	end

	return true
end

--- Defer a plugin's setup to keep startup snappy
---@param name string
---@param config function|table
---@param opts? { event: string|string[], timer: number }
function M.defer(name, config, opts)
	opts = opts or {}
	local function load()
		M.setup(name, config)
	end

	if opts.event then
		vim.api.nvim_create_autocmd(opts.event, {
			callback = load,
			once = true,
			desc = "Lazy load: " .. name,
		})
	elseif opts.timer then
		vim.defer_fn(load, opts.timer)
	else
		vim.schedule(load)
	end
end

return M
