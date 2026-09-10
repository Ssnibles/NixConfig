-- ── Terminal toggle ───────────────────────────────────────────────────

local function find_terminal_buf()
	local best, best_used = nil, -1
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
			local info = vim.fn.getbufinfo(buf)[1]
			local used = (info and info.lastused) or 0
			if used > best_used then best_used, best = used, buf end
		end
	end
	return best
end

local function find_terminal_win(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then return win end
	end
	return nil
end

local function open_terminal(position, existing)
	if position == "float" then
		local buf = existing or vim.api.nvim_create_buf(false, true)
		local w = math.floor(vim.o.columns * 0.8)
		local h = math.floor(vim.o.lines * 0.8)
		vim.api.nvim_open_win(buf, true, {
			relative = "editor", width = w, height = h,
			row = math.floor((vim.o.lines - h) / 2),
			col = math.floor((vim.o.columns - w) / 2),
			style = "minimal", border = "rounded",
		})
		if existing then
			vim.cmd("buffer " .. buf)
			vim.cmd("startinsert")
		else
			vim.cmd("terminal")
		end
		return
	end

	local cmd = "botright split"
	if position == "bottom" then
		cmd = "botright " .. math.floor(vim.o.lines * 0.30) .. "split"
	elseif position == "right" then
		cmd = "botright vertical " .. math.floor(vim.o.columns * 0.30) .. "split"
	end

	if existing then
		vim.cmd(cmd .. " | buffer " .. existing)
		vim.cmd("startinsert")
	else
		vim.cmd(cmd .. " | terminal")
	end
end

local function toggle_terminal(position)
	local buf = find_terminal_buf()
	if buf then
		local win = find_terminal_win(buf)
		if win then
			vim.api.nvim_win_hide(win)
			return
		end
		open_terminal(position, buf)
		return
	end
	open_terminal(position)
end

vim.keymap.set("n", "<leader>tt", function() toggle_terminal("bottom") end, { desc = "Toggle terminal (bottom)" })
vim.keymap.set("n", "<leader>tr", function() toggle_terminal("right") end, { desc = "Toggle terminal (right)" })
vim.keymap.set("n", "<leader>tf", function() toggle_terminal("float") end, { desc = "Toggle terminal (float)" })

-- ── Terminal autocommands ────────────────────────────────────────────

vim.api.nvim_create_autocmd({ "TermOpen", "BufWinEnter" }, {
	callback = function()
		if vim.bo.buftype ~= "terminal" then return end
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.wo.cursorline = false
		vim.wo.statuscolumn = ""
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function() vim.cmd("startinsert") end,
})
