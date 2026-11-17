-- Buffer-local find and replace, filled from the word or selection under the
-- cursor.

local M = {}

--- @param default string?
function M.prompt(default)
	vim.ui.input({ prompt = "Find in buffer: ", default = default or "" }, function(find)
		if not find or find == "" then
			return
		end
		vim.ui.input({ prompt = "Replace with: " }, function(replace)
			if replace == nil then
				return
			end
			local keys = (":<C-u>%%s/\\V%s/%s/g"):format(vim.fn.escape(find, "/"), vim.fn.escape(replace, "/&"))
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
		end)
	end)
end

--- Replace the current word.
function M.word()
	M.prompt(vim.fn.expand("<cword>"))
end

--- Replace the visual selection's first line.
function M.selection()
	local selection = table
		.concat(vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { type = vim.fn.mode() }), "\n")
		:match("^[^\r\n]*")
	M.prompt(selection)
end

return M
