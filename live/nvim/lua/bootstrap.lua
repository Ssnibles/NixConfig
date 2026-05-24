local M = {}

function M.safe_require(module)
	local ok, err = pcall(require, module)
	if not ok then
		vim.schedule(function()
			vim.notify(("Failed loading %s: %s"):format(module, err), vim.log.levels.ERROR)
		end)
	end
	return ok
end

function M.load_modules(modules)
	for _, module in ipairs(modules) do
		M.safe_require(module)
	end
end

function M.defer_modules(modules, event)
	if not modules or #modules == 0 then
		return
	end

	vim.api.nvim_create_autocmd(event, {
		once = true,
		callback = function()
			if vim.v.exiting ~= 0 then
				return
			end
			vim.schedule(function()
				M.load_modules(modules)
			end)
		end,
	})
end

return M
