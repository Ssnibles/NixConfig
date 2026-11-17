-- Command-line presentation. ui2 fires FileType cmd so its window can be styled
-- locally; the search highlight clears are ui2's own defaults.
local function style(win)
	vim.wo[win].winhighlight = "Normal:CmdlineBar,MsgArea:CmdlineBar,Search:,CurSearch:,IncSearch:"
	vim.wo[win].winblend = 0
	vim.wo[win].scrolloff = 0
	vim.wo[win].sidescrolloff = 0
	vim.wo[win].cursorline = false
end
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserCmdline", { clear = true }),
	pattern = "cmd",
	callback = function(ev)
		local win = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_get_buf(win) == ev.buf then
			style(win)
		end
	end,
})
-- The command-line window (q:) gets more room than the default seven lines.
vim.o.cmdwinheight = 15
-- Style a command window that ui2 created before this file loaded.
for _, win in ipairs(vim.api.nvim_list_wins()) do
	local buf = vim.api.nvim_win_get_buf(win)
	if vim.bo[buf].filetype == "cmd" then
		style(win)
	end
end
