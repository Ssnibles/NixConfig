-- Terminal toggles. One shell buffer is reused, so its state survives hiding
-- and reopening. Picker and dev-plugin terminal buffers are never adopted.

local util = require("util")

local function is_shell(buf)
	return vim.api.nvim_buf_is_valid(buf)
		and vim.bo[buf].buftype == "terminal"
		and not util.is_helper_ft(vim.bo[buf].filetype)
end

-- The most recently used shell buffer, if there is one.
local function shell_buf()
	local best, best_used = nil, -1
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_shell(buf) then
			local used = vim.fn.getbufinfo(buf)[1].lastused or 0
			if used > best_used then
				best, best_used = buf, used
			end
		end
	end
	return best
end

local function open_window(position)
	if position == "float" then
		local width = math.floor(vim.o.columns * 0.8)
		local height = math.floor(vim.o.lines * 0.8)
		vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
			relative = "editor",
			width = width,
			height = height,
			row = math.floor((vim.o.lines - height) / 2),
			col = math.floor((vim.o.columns - width) / 2),
			style = "minimal",
			border = "rounded",
			title = " terminal ",
			title_pos = "center",
		})
	elseif position == "right" then
		vim.cmd("belowright " .. math.floor(vim.o.columns * 0.3) .. "vsplit")
	else
		vim.cmd("belowright " .. math.floor(vim.o.lines * 0.3) .. "split")
	end
end

local function toggle(position)
	local buf = shell_buf()
	local win = buf and vim.fn.bufwinid(buf) or -1
	if win ~= -1 then
		-- Hiding the last window is an error, and there is nowhere to return to.
		if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)) > 1 then
			vim.api.nvim_win_hide(win)
		end
		return
	end
	open_window(position)
	if buf then
		vim.api.nvim_win_set_buf(0, buf)
	else
		vim.cmd("terminal")
	end
	vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>tt", function()
	toggle("bottom")
end, { desc = "Toggle terminal (bottom)" })
vim.keymap.set("n", "<leader>tr", function()
	toggle("right")
end, { desc = "Toggle terminal (right)" })
vim.keymap.set("n", "<leader>tf", function()
	toggle("float")
end, { desc = "Toggle terminal (float)" })

vim.api.nvim_create_autocmd({ "TermOpen", "BufWinEnter" }, {
	group = vim.api.nvim_create_augroup("UserTerminal", { clear = true }),
	callback = function(ev)
		if vim.bo[ev.buf].buftype ~= "terminal" then
			return
		end
		-- 'number', 'relativenumber' and 'signcolumn' are already forced off by
		-- the default TermOpen autocmd; only these two are not.
		vim.wo.cursorline = false
		vim.wo.statuscolumn = ""
		if ev.event == "TermOpen" then
			vim.cmd("startinsert")
		end
	end,
})
