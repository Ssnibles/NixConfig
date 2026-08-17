local M = {}

local loaded = {}

--- Helper to ensure value is wrapped in a list table
local function to_list(v)
	if v == nil then return {} end
	return type(v) == "table" and v or { v }
end

--- Safely load a single module with error handling
local function load_one(mod)
	if not mod or loaded[mod] ~= nil then
		return loaded[mod] or false
	end

	local ok, err = pcall(require, mod)
	loaded[mod] = ok

	if not ok then
		vim.schedule(function()
			vim.notify(
				string.format("Failed loading %s:\n%s", mod, err),
				vim.log.levels.ERROR,
				{ title = "Module Loader" }
			)
		end)
	end
	return ok
end

--- Parse spec table or string into standardized spec info
local function parse_spec(spec)
	if type(spec) == "string" then
		return { module = spec }
	end
	if type(spec) ~= "table" then
		return nil
	end

	local mod = spec.module or spec[1]
	if not mod then
		return nil
	end

	return {
		module = mod,
		ft = spec.ft or spec.filetype,
		event = spec.event or spec.events,
		cmd = spec.cmd or spec.cmds or spec.command or spec.commands,
		keys = spec.keys or spec.keymaps,
		defer = spec.defer or spec.delay,
	}
end

--- Trigger setup implementations
local triggers = {
	ft = function(mod, fts, load_fn)
		fts = to_list(fts)
		-- If a matching buffer is already loaded, trigger immediately
		local has_contains = vim.list_contains or vim.tbl_contains
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and has_contains(fts, vim.bo[buf].filetype) then
				load_fn()
				return
			end
		end

		vim.api.nvim_create_autocmd("FileType", {
			pattern = fts,
			once = true,
			callback = load_fn,
		})
	end,

	event = function(_, events, load_fn)
		vim.api.nvim_create_autocmd(to_list(events), {
			once = true,
			callback = load_fn,
		})
	end,

	cmd = function(mod, cmds, load_fn)
		for _, cmd in ipairs(to_list(cmds)) do
			vim.api.nvim_create_user_command(cmd, function(opts)
				pcall(vim.api.nvim_del_user_command, cmd)
				load_fn()
				vim.cmd({ cmd = cmd, bang = opts.bang, args = opts.fargs })
			end, {
				nargs = "*",
				bang = true,
				complete = function()
					pcall(vim.api.nvim_del_user_command, cmd)
					load_fn()
					return {}
				end,
				desc = "Lazy load " .. mod,
			})
		end
	end,

	keys = function(mod, keys, load_fn)
		for _, key in ipairs(to_list(keys)) do
			local lhs = type(key) == "string" and key or (key[1] or key.lhs)
			local mode = (type(key) == "table" and key.mode) or "n"
			local desc = (type(key) == "table" and key.desc) or ("Lazy load " .. mod)

			if lhs then
				vim.keymap.set(mode, lhs, function()
					pcall(vim.keymap.del, mode, lhs)
					load_fn()
					vim.api.nvim_feedkeys(vim.keycode(lhs), "t", false)
				end, { desc = desc, silent = true })
			end
		end
	end,
}

--- Setup deferred load for a single item
local function setup_lazy_item(item)
	local spec = parse_spec(item)
	if not spec then
		return
	end

	local load_fn = function()
		return load_one(spec.module)
	end
	local has_trigger = false

	for type_key, setup_fn in pairs(triggers) do
		if spec[type_key] then
			has_trigger = true
			setup_fn(spec.module, spec[type_key], load_fn)
		end
	end

	if not has_trigger or spec.defer then
		local delay = type(spec.defer) == "number" and spec.defer or 50
		local do_defer = function()
			vim.defer_fn(function()
				if not vim.v.exiting or vim.v.exiting == 0 then
					load_fn()
				end
			end, delay)
		end

		if vim.v.vim_did_enter == 1 then
			do_defer()
		else
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = do_defer,
			})
		end
	end
end

--- Load core modules immediately and deferred modules on demand / lazy triggers
function M.load_modules(core, deferred)
	for _, item in ipairs(core or {}) do
		local spec = parse_spec(item)
		if spec and spec.module then
			load_one(spec.module)
		end
	end

	for _, item in ipairs(deferred or {}) do
		setup_lazy_item(item)
	end
end

return M

