local function find_terminal_buf()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_is_valid(buf) then
			return buf
		end
	end
	return nil
end

local function find_terminal_win(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			return win
		end
	end
	return nil
end

local function open_terminal(position, existing_buf)
	local cmd = "botright"
	if position == "right" then
		cmd = "botright vertical"
	elseif position == "float" then
		cmd = "float"
	end

	if cmd == "float" then
		local buf = existing_buf or vim.api.nvim_create_buf(false, true)
		local width = math.floor(vim.o.columns * 0.8)
		local height = math.floor(vim.o.lines * 0.8)
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
		})
		if not existing_buf then
			vim.cmd("terminal")
		else
			vim.cmd("buffer " .. buf)
			vim.cmd("startinsert")
		end
	else
		if existing_buf then
			vim.cmd(cmd .. " split | buffer " .. existing_buf)
			vim.cmd("startinsert")
		else
			vim.cmd(cmd .. " split | terminal")
		end
	end
end

local function toggle_terminal(position)
	local term_buf = find_terminal_buf()
	if term_buf then
		local term_win = find_terminal_win(term_buf)
		if term_win then
			vim.api.nvim_win_hide(term_win)
			return
		end
		open_terminal(position, term_buf)
		return
	end
	open_terminal(position)
end

vim.keymap.set("n", "<leader>tt", function()
	toggle_terminal("bottom")
end, { desc = "Toggle terminal (bottom)" })

vim.keymap.set("n", "<leader>tr", function()
	toggle_terminal("right")
end, { desc = "Toggle terminal (right)" })

vim.keymap.set("n", "<leader>tf", function()
	toggle_terminal("float")
end, { desc = "Toggle terminal (float)" })

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.wo.cursorline = false
		vim.cmd("startinsert")
	end,
})

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
