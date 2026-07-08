-- Terminal integration using native Neovim terminal.

local function open_terminal(position)
	local cmd = "botright"
	if position == "right" then
		cmd = "botright vertical"
	elseif position == "float" then
		cmd = "float"
	end

	if cmd == "float" then
		local buf = vim.api.nvim_create_buf(false, true)
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
		vim.cmd("terminal")
	else
		vim.cmd(cmd .. " split | terminal")
	end
end

local function toggle_terminal(position)
	local term_bufs = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buftype == "terminal" then
			table.insert(term_bufs, buf)
		end
	end

	for _, buf in ipairs(term_bufs) do
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == buf then
				vim.api.nvim_win_close(win, true)
				return
			end
		end
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
