-- Version control: gitsigns, grug-far and the jjui TUI.
local external = require("external")
local gitsigns = require("gitsigns")
local M = {}
-- Gitsigns ------------------------------------------------------------------
gitsigns.setup({
	signcolumn = true,
	numhl = true,
	current_line_blame = true,
	current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", virt_text_priority = 5000, delay = 800 },
	current_line_blame_formatter = function(name, info)
		local bufnr = vim.api.nvim_get_current_buf()
		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
		if vim.diagnostic.is_enabled({ bufnr = bufnr }) and #vim.diagnostic.get(bufnr, { lnum = lnum }) > 0 then
			return {}
		end
		if info.author == name then
			info.author = "You"
		end
		local days = math.floor((os.time() - info.author_time) / 86400)
		local when
		if days < 1 then
			when = "today"
		elseif days == 1 then
			when = "1 day ago"
		elseif days < 8 then
			when = days .. " days ago"
		else
			when = os.date("%d-%m-%Y", info.author_time)
		end
		return { { ("  %s, %s — %s"):format(info.author, when, info.summary), "GitSignsCurrentLineBlame" } }
	end,
	on_attach = function(bufnr)
		local function map(keys, rhs, desc)
			vim.keymap.set("n", keys, rhs, { buffer = bufnr, desc = desc })
		end
		map("]g", gitsigns.next_hunk, "Next hunk")
		map("[g", gitsigns.prev_hunk, "Prev hunk")
		map("<leader>gp", gitsigns.preview_hunk, "Preview hunk")
		map("<leader>gs", gitsigns.stage_hunk, "Stage hunk")
		map("<leader>gu", gitsigns.reset_hunk, "Unstage/reset hunk")
		map("<leader>gb", gitsigns.blame_line, "Blame line")
		map("<leader>gD", gitsigns.diffthis, "Diff this")
	end,
})
-- Inline blame and inline diagnostics both render at end of line. Gitsigns has
-- no option to hide blame per line, so its own extmark (namespace
-- "gitsigns_blame", id 1) is removed when a diagnostic lands and the blame is
-- refreshed when the diagnostic goes away. Re-check on gitsigns upgrades.
vim.api.nvim_create_autocmd("DiagnosticChanged", {
	group = vim.api.nvim_create_augroup("UserGitBlame", { clear = true }),
	callback = function(args)
		local bufnr = args.buf
		if not vim.api.nvim_buf_is_valid(bufnr) or bufnr ~= vim.api.nvim_get_current_buf() then
			return
		end
		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
		if #vim.diagnostic.get(bufnr, { lnum = lnum }) > 0 then
			local ns = vim.api.nvim_create_namespace("gitsigns_blame")
			pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, 1)
		else
			pcall(function()
				require("gitsigns.current_line_blame").update(bufnr)
			end)
		end
	end,
})
-- Grug-far (project-wide find and replace)
require("grug-far").setup()
-- Jujutsu TUI ---------------------------------------------------------------
--- Open jjui in a centred float.
function M.jjui()
	local jjui = external.jjui()
	if not jjui then
		vim.notify("jjui is not installed.", vim.log.levels.WARN)
		return
	end
	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		title = " jjui ",
		title_pos = "center",
	})
	vim.fn.termopen(jjui, {
		on_exit = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
			vim.cmd.checktime()
		end,
	})
	-- Without a filetype the terminal toggle would adopt this buffer as its shell.
	vim.bo[buf].filetype = "jj"
end
return M
