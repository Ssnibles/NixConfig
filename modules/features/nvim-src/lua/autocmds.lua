-- Base editor autocommands. One augroup per feature so a re-source replaces a
-- handler instead of stacking another one.

local autocmd = vim.api.nvim_create_autocmd

local function group(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Filetype policy -----------------------------------------------------------

-- Filetypes closed with 'q' or <Esc>.
local close_with_q = { help = true, man = true, qf = true, checkhealth = true, oil = true, ["grug-far"] = true }
-- Filetypes that skip trailing whitespace trimming.
local trim_skip = { markdown = true, ["markdown.mdx"] = true, text = true, gitcommit = true, diff = true }
-- Prose: spell checking and wrapping on.
local prose = { markdown = true, ["markdown.mdx"] = true, text = true, gitcommit = true }
-- Filetypes folded by indent instead of the treesitter foldexpr.
local fold_indent = {
	markdown = true,
	["markdown.mdx"] = true,
	text = true,
	gitcommit = true,
	typst = true,
	yaml = true,
	json = true,
	toml = true,
}
-- Indent folders that start unfolded: prose plus Typst.
local fold_off = vim.tbl_extend("force", {}, prose, { typst = true })

autocmd("FileType", {
	group = group("UserFileType"),
	callback = function(ev)
		local buf = ev.buf
		local ft = vim.bo[buf].filetype

		-- Not every filetype has a parser installed.
		if not vim.b[buf].large_file then
			pcall(vim.treesitter.start, buf)
		end

		-- Keep 'r' so <CR> continues comments, drop 'o' so `o` does not insert
		-- one, and drop 'c' so textwidth does not wrap. Assign the string
		-- rather than using :remove(): on 0.13 the ftplugin sets the option
		-- after this callback and the remove operation does not see it.
		local fo = vim.bo[buf].formatoptions:gsub("[co]", "")
		if not fo:find("r") then
			fo = fo .. "r"
		end
		vim.bo[buf].formatoptions = fo

		if fold_indent[ft] then
			vim.wo.foldmethod = "indent"
		end
		if fold_off[ft] then
			vim.wo.foldenable = false
		end
		if prose[ft] then
			vim.wo.spell = true
			vim.wo.wrap = true
		end
		if ft == "lua" or ft == "vim" then
			vim.bo[buf].keywordprg = ":help"
		end
		if close_with_q[ft] then
			vim.keymap.set("n", "q", "<cmd>silent! close<CR>", { buffer = buf, desc = "Close window" })
			vim.keymap.set("n", "<Esc>", "<cmd>silent! close<CR>", { buffer = buf, desc = "Close window" })
		end
	end,
})

-- Whitespace ----------------------------------------------------------------

autocmd("BufWritePre", {
	group = group("UserWhitespace"),
	callback = function()
		if vim.bo.buftype ~= "" or trim_skip[vim.bo.filetype] then
			return
		end
		local trailspace = require("mini.trailspace")
		trailspace.trim()
		trailspace.trim_last_lines()
	end,
})

-- Highlight yanked and put regions. vim.hl.on_yank() is deprecated on 0.13;
-- hl_op() replaces it and also covers TextPutPost.
autocmd({ "TextYankPost", "TextPutPost" }, {
	group = group("UserYank"),
	callback = function()
		vim.hl.hl_op({ timeout = 200 })
	end,
})

-- Windows and buffers -------------------------------------------------------

autocmd("FocusGained", { group = group("UserFocus"), command = "checktime" })
autocmd("VimResized", { group = group("UserResize"), command = "wincmd =" })

autocmd("BufReadPost", {
	group = group("UserCursorRestore"),
	callback = function(ev)
		local ft = vim.bo[ev.buf].filetype
		if ft == "gitcommit" or ft == "gitrebase" then
			return
		end
		local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Absolute line numbers while typing, relative the rest of the time. The
-- window variable records the user's intent so <leader>tn survives the event.
autocmd({ "InsertEnter", "InsertLeave" }, {
	group = group("UserNumberToggle"),
	callback = function(ev)
		if vim.bo.buftype ~= "" or vim.w.relativenumber_enabled == false then
			return
		end
		vim.wo.relativenumber = ev.event == "InsertLeave"
	end,
})

autocmd({ "WinEnter", "WinLeave" }, {
	group = group("UserCursorline"),
	callback = function(ev)
		if vim.bo.buftype ~= "terminal" then
			vim.wo.cursorline = ev.event == "WinEnter"
		end
	end,
})

-- Large files ---------------------------------------------------------------

local LARGE_FILE_MB = 5

autocmd("BufReadPre", {
	group = group("UserLargeFile"),
	callback = function(ev)
		local path = vim.api.nvim_buf_get_name(ev.buf)
		if path == "" or vim.bo[ev.buf].buftype ~= "" then
			return
		end
		local ok, stat = pcall(vim.uv.fs_stat, path)
		if ok and stat and (stat.size / (1024 * 1024)) > LARGE_FILE_MB then
			vim.b[ev.buf].large_file = true
		end
	end,
})

autocmd("BufReadPost", {
	group = group("UserLargeFile"),
	callback = function(ev)
		if not vim.b[ev.buf].large_file then
			return
		end
		vim.opt_local.foldmethod = "manual"
		vim.opt_local.foldenable = false
		vim.bo[ev.buf].syntax = ""
		pcall(vim.treesitter.stop, ev.buf)
	end,
})
