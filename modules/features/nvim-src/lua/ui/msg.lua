-- Message windows. ui2 frames the message window itself, but with 'cmdheight'
-- at 0 it leaves the pager and dialog without an edge, and those fill the screen
-- so only a top rule can be drawn.

local function rule()
	local sep = vim.opt.fillchars:get().msgsep or "─"
	return { "", { sep, "MsgSeparator" }, "", "", "", "", "", "" }
end

local function style(win)
	vim.wo[win].winblend = 0
	if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "msg" then
		vim.api.nvim_win_set_config(win, { border = "rounded" })
	else
		vim.api.nvim_win_set_config(win, { border = rule() })
	end
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserMsg", { clear = true }),
	pattern = { "msg", "dialog", "pager" },
	callback = function(ev)
		local win = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_get_buf(win) == ev.buf then
			style(win)
		end
	end,
})

-- Style windows that ui2 created before this file loaded.
for _, win in ipairs(vim.api.nvim_list_wins()) do
	local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
	if ft == "msg" or ft == "dialog" or ft == "pager" then
		style(win)
	end
end
