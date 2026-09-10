-- =============================================================================
-- jj (Jujutsu) Integration — floating jjui launcher
-- =============================================================================
-- Opens jjui in a centred floating terminal window.  jjui is the TUI for the
-- Jujutsu VCS and replaces the previous neogit integration.
-- Keymaps:
--   <leader>gg  → open jjui float (normal mode)
--   <Esc><Esc>  → exit terminal mode inside the float without closing jjui
-- =============================================================================

local function open_jjui()
	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " jjui ",
		title_pos = "center",
	})

	-- Inherit terminal colours / no line numbers
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].cursorline = false

	vim.fn.termopen("jjui", {
		on_exit = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})

	vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>gg", open_jjui, { desc = "Open jjui (Jujutsu TUI)" })
