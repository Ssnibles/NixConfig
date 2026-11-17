-- Search, git and diagnostic segments.

local icons = require("ui.statusline.icons")
local util = require("ui.statusline.util")

local M = {}

local search_cache = {}

function M.search()
	local kind = vim.fn.getcmdtype()
	local pattern
	if kind == "/" or kind == "?" then
		pattern = vim.fn.getcmdline()
		if pattern == "" then
			return nil
		end
	elseif vim.v.hlsearch == 1 then
		pattern = vim.fn.getreg("/")
	else
		return nil
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local key = table.concat({
		pattern,
		bufnr,
		vim.api.nvim_buf_get_changedtick(bufnr),
		cursor[1],
		cursor[2],
		tostring(vim.o.ignorecase),
		tostring(vim.o.smartcase),
		tostring(vim.o.magic),
		tostring(vim.o.wrapscan),
	}, "\0")
	if search_cache.key == key then
		return search_cache.text
	end

	local options = { maxcount = 999, timeout = 25 }
	local previous
	if kind == "/" or kind == "?" then
		previous = vim.fn.getreg("/")
		options.pattern = pattern
	end
	local ok, count = pcall(vim.fn.searchcount, options)
	if previous then
		vim.fn.setreg("/", previous)
	end

	local text
	if ok and count and count.total and count.total > 0 then
		local capped = count.incomplete == 1 and "+" or ""
		local direction = kind == "/" and " FWD" or kind == "?" and " BWD" or ""
		text = ("%%#StlSearch# %s %d/%d%s%s %%#StlBar#"):format(
			icons.search,
			count.current or 0,
			count.total,
			capped,
			direction
		)
	elseif kind == "/" or kind == "?" then
		text = ("%%#StlSearch# %s NO MATCH %%#StlBar#"):format(icons.search)
	end
	search_cache = { key = key, text = text }
	return text
end

function M.git()
	local branch = vim.b.gitsigns_head
	if not branch or branch == "" then
		return nil
	end
	local parts = { (" %s %s"):format(icons.git, util.escape(branch)) }
	local diff = vim.b.gitsigns_status_dict
	if diff then
		if (diff.added or 0) > 0 then
			parts[#parts + 1] = ("%%#StlGitAdd#+%d%%#StlGit#"):format(diff.added)
		end
		if (diff.changed or 0) > 0 then
			parts[#parts + 1] = ("%%#StlGitChange#~%d%%#StlGit#"):format(diff.changed)
		end
		if (diff.removed or 0) > 0 then
			parts[#parts + 1] = ("%%#StlGitDelete#-%d%%#StlGit#"):format(diff.removed)
		end
	end
	return "%#StlGit#" .. table.concat(parts, " ") .. " %#StlBar#"
end

local diagnostic_cache
vim.api.nvim_create_autocmd("DiagnosticChanged", {
	group = vim.api.nvim_create_augroup("UserStatusline", { clear = true }),
	callback = function()
		diagnostic_cache = nil
	end,
})

function M.diagnostics()
	local bufnr = vim.api.nvim_get_current_buf()
	if diagnostic_cache and diagnostic_cache.bufnr == bufnr then
		return diagnostic_cache.text
	end
	local counts = vim.diagnostic.count(bufnr)
	local errors = counts[vim.diagnostic.severity.ERROR] or 0
	local warnings = counts[vim.diagnostic.severity.WARN] or 0
	local parts = {}
	if errors > 0 then
		parts[#parts + 1] = ("%%#StlDiagError#%s %d%%#StlDiag#"):format(icons.error, errors)
	end
	if warnings > 0 then
		parts[#parts + 1] = ("%%#StlDiagWarn#%s %d%%#StlDiag#"):format(icons.warn, warnings)
	end
	local text = #parts > 0 and ("%#StlDiag# " .. table.concat(parts, " ") .. " %#StlBar#") or nil
	diagnostic_cache = { bufnr = bufnr, text = text }
	return text
end

return M
