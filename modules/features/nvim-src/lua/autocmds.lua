local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Filetypes closed by pressing 'q' or '<Esc>'
local close_with_q = { "help", "man", "qf", "checkhealth", "notify", "oil", "grug-far", "cargo" }

-- Filetypes that skip trailing whitespace trimming
local trim_skip = { markdown = true, ["markdown.mdx"] = true, text = true, gitcommit = true, diff = true }

-- Filetypes using indent folding instead of treesitter
local fold_indent = { "markdown", "markdown.mdx", "text", "gitcommit", "typst", "txt", "yaml", "json", "toml" }

-- ── Tree-sitter highlighting ─────────────────────────────────────────
autocmd("FileType", {
	group = augroup,
	callback = function(ev)
		if vim.b[ev.buf].large_file then
			return
		end
		pcall(vim.treesitter.start, ev.buf)
	end,
})

-- ── Trim trailing whitespace on save ─────────────────────────────────
autocmd("BufWritePre", {
	group = augroup,
	callback = function()
		if vim.bo.buftype ~= "" or trim_skip[vim.bo.filetype] then
			return
		end
		local ok, trailspace = pcall(require, "mini.trailspace")
		if ok then
			trailspace.trim()
			trailspace.trim_last_lines()
		end
	end,
})

-- ── Yank/paste highlight ────────────────────────────────────────────
-- vim.hl.on_yank() is deprecated in 0.13 (removed in 0.14); vim.hl.hl_op()
-- replaces it and also supports TextPutPost for paste highlighting.
autocmd({ "TextYankPost", "TextPutPost" }, {
	group = augroup,
	callback = function()
		vim.hl.hl_op({ timeout = 200 })
	end,
})

-- ── Check for external changes on focus ──────────────────────────────
autocmd("FocusGained", { group = augroup, command = "checktime" })

-- ── Restore cursor position ──────────────────────────────────────────
autocmd("BufReadPost", {
	group = augroup,
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

-- ── Close utility windows with q / <Esc> ────────────────────────────
autocmd("FileType", {
	group = augroup,
	pattern = close_with_q,
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
		vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
	end,
})

-- ── Equalise splits on resize ────────────────────────────────────────
autocmd("VimResized", { group = augroup, command = "wincmd =" })

-- ── Auto-comment formatting ──────────────────────────────────────────
-- Keep 'r' so <CR> in insert mode continues comments (block comments, doc comments, etc.)
-- Remove 'o' so 'o' in normal mode doesn't auto-insert comments, and 'c' to prevent textwidth auto-wrapping.
autocmd("FileType", {
	group = augroup,
	callback = function()
		-- NOTE: `vim.opt_local.formatoptions:remove()` is a no-op inside the
		-- FileType event on Neovim 0.13 nightly (the new `vim.opt` `remove`
		-- operation doesn't see the value the ftplugin just assigned). Assigning
		-- the string directly works, so do that instead of mutating in place.
		local fo = vim.bo.formatoptions:gsub("[co]", "")
		if not fo:find("r") then
			fo = fo .. "r"
		end
		vim.bo.formatoptions = fo
	end,
})

-- ── Prose filetypes: spell + wrap ────────────────────────────────────
autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "markdown.mdx", "text", "gitcommit" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
		-- Tree-sitter is kept on for Markdown: markview.nvim uses it to render.
	end,
})

-- ── Relative line numbers toggle on insert ───────────────────────────
-- Only auto-hide relative numbers when the user hasn't disabled them with
-- <leader>tn (tracked via vim.g.relativenumber_enabled).
local function relativenumber_enabled()
	return vim.g.relativenumber_enabled ~= false
end

autocmd({ "InsertEnter", "InsertLeave" }, {
	group = augroup,
	callback = function(ev)
		if vim.bo.buftype == "" and relativenumber_enabled() then
			-- Absolute numbers while typing, relative the rest of the time.
			vim.opt_local.relativenumber = ev.event == "InsertLeave"
		end
	end,
})

-- ── Cursorline follows focus ─────────────────────────────────────────
autocmd({ "WinEnter", "WinLeave" }, {
	group = augroup,
	callback = function(ev)
		if vim.bo.buftype ~= "terminal" then
			vim.opt_local.cursorline = ev.event == "WinEnter"
		end
	end,
})

-- ── Indent folding for structured text ───────────────────────────────
autocmd("FileType", {
	group = augroup,
	pattern = fold_indent,
	callback = function()
		vim.opt_local.foldmethod = "indent"
		vim.opt_local.foldenable = false
	end,
})

-- ── Help keywordprg for Lua/Vim ──────────────────────────────────────
autocmd("FileType", {
	group = augroup,
	pattern = { "lua", "vim" },
	callback = function()
		vim.bo.keywordprg = ":help"
	end,
})

-- ── Typst preview & Zathura sync ─────────────────────────────────────
autocmd("FileType", {
	group = augroup,
	pattern = "typst",
	callback = function(ev)
		vim.keymap.set("n", "<leader>tp", function()
			vim.cmd("TypstPreviewToggle")
		end, { buffer = ev.buf, desc = "Toggle Typst preview" })

		vim.keymap.set("n", "<leader>zo", function()
			local pdf = vim.fn.expand("%:p:r") .. ".pdf"
			if vim.fn.filereadable(pdf) == 1 then
				vim.system({
					"zathura",
					"--synctex-forward=" .. vim.fn.line(".") .. ":0:" .. vim.api.nvim_buf_get_name(ev.buf),
					pdf,
				}, { detach = true })
			else
				vim.notify("PDF not found: " .. pdf, vim.log.levels.WARN)
			end
		end, { buffer = ev.buf, desc = "Open PDF in Zathura" })
	end,
})

-- ── Large file performance guard ─────────────────────────────────────
-- Flag big files in BufReadPre (before FileType starts Tree-sitter) so the
-- expensive highlighting is never enabled for them.
local LARGE_FILE_MB = 5

autocmd("BufReadPre", {
	group = augroup,
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
	group = augroup,
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
