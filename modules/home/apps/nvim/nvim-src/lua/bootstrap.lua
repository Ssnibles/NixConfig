local M = {}

local function load_one(module)
	local ok, err = pcall(require, module)
	if not ok then
		vim.schedule(function()
			vim.notify(("Failed loading %s: %s"):format(module, err), vim.log.levels.ERROR)
		end)
	end
	return ok
end

local function load_all(modules)
	for _, module in ipairs(modules) do
		load_one(module)
	end
end

function M.load_modules(core, deferred)
	load_all(core)

	if deferred and #deferred > 0 then
		vim.api.nvim_create_autocmd("VimEnter", {
			once = true,
			callback = function()
				if vim.v.exiting ~= 0 then
					return
				end
				load_all(deferred)
			end,
		})
	end
end

return M
