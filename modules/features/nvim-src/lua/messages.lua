-- =============================================================================
-- Messages: Route cmdline/internal messages to Fidget notifications
-- =============================================================================
local M = {}

local in_notify = false
local attached = false
local ns = vim.api.nvim_create_namespace("fidget_msg_router")

local ignore_kinds = {
	search_cmd = true,
	search_count = true,
	empty = true,
	undo = true,
}

function M.setup()
	if attached then
		return
	end
	attached = true

	pcall(vim.ui_attach, ns, { ext_messages = true }, function(event, ...)
		if event ~= "msg_show" or in_notify then
			return
		end

		local kind, content, replace_last, _, _, id = ...
		if ignore_kinds[kind] then
			return
		end

		local text_segments = {}
		for _, chunk in ipairs(content or {}) do
			if type(chunk) == "table" and chunk[2] then
				table.insert(text_segments, chunk[2])
			end
		end
		local msg = vim.trim(table.concat(text_segments))
		if msg == "" then
			return
		end

		-- Suppress all undo and redo messages
		if
			kind == "undo"
			or msg:match("Already at oldest change")
			or msg:match("Already at newest change")
			or msg:match("%d+%s+lines?%s+less")
			or msg:match("%d+%s+lines?%s+more")
			or msg:match("%d+%s+changes?;%s+before")
			or msg:match("%d+%s+changes?;%s+after")
		then
			return
		end

		-- Suppress initial bufwrite message before line/byte counts are calculated
		if kind == "progress" and id == "bufwrite" then
			local has_stat = msg:match("%d+%s*line")
				or msg:match("%d+L")
				or msg:match("%d+%s*byte")
				or msg:match("%d+B")
				or msg:match("written")
				or msg:match("%[w%]")
			if not has_stat then
				return
			end
		end

		local level = vim.log.levels.INFO
		if
			kind == "emsg"
			or kind == "echoerr"
			or kind == "lua_error"
			or kind == "rpc_error"
			or kind == "shell_err"
		then
			level = vim.log.levels.ERROR
		elseif kind == "wmsg" then
			level = vim.log.levels.WARN
		end

		vim.schedule(function()
			in_notify = true
			local ok, fidget = pcall(require, "fidget")
			if ok and fidget.notify then
				fidget.notify(msg, level, { key = id or msg })
			else
				vim.notify(msg, level)
			end
			in_notify = false
		end)
	end)
end

return M
