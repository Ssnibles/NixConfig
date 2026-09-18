local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Filetypes closed by pressing 'q' or '<Esc>'
local close_with_q = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "oil", "grug-far", "cargo" }

-- Filetypes that skip trailing whitespace trimming
local trim_skip = { markdown = true, text = true, gitcommit = true, diff = true }

-- Filetypes using indent folding instead of treesitter
local fold_indent = { "markdown", "markdown.mdx", "text", "gitcommit", "typst", "txt", "yaml", "json", "toml" }

-- ── Tree-sitter highlighting ─────────────────────────────────────────
autocmd("FileType", {
	group = augroup,
	callback = function(ev)
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



-- ── Yank highlight ───────────────────────────────────────────────────
autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank({ timeout = 200 })
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

-- ── Equalize splits on resize ────────────────────────────────────────
autocmd("VimResized", { group = augroup, command = "wincmd =" })

-- ── Auto-comment formatting ──────────────────────────────────────────
-- Keep 'r' so <CR> in insert mode continues comments (block comments, doc comments, etc.)
-- Remove 'o' so 'o' in normal mode doesn't auto-insert comments, and 'c' to prevent textwidth auto-wrapping.
autocmd("FileType", {
	group = augroup,
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "o" })
		vim.opt_local.formatoptions:append({ "r" })
	end,
})

-- ── Prose filetypes: spell + wrap ────────────────────────────────────
autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "markdown.mdx", "text", "gitcommit" },
	callback = function(ev)
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
		if vim.fn.has("nvim-0.12") == 1 then
			if vim.bo[ev.buf].filetype == "markdown" or vim.bo[ev.buf].filetype == "markdown.mdx" then
				pcall(vim.treesitter.stop, ev.buf)
			end
		end
	end,
})

-- ── Relative line numbers toggle on insert ───────────────────────────
autocmd("InsertEnter", {
	group = augroup,
	callback = function()
		if vim.bo.buftype == "" then
			vim.opt_local.relativenumber = false
		end
	end,
})
autocmd("InsertLeave", {
	group = augroup,
	callback = function()
		if vim.bo.buftype == "" then
			vim.opt_local.relativenumber = true
		end
	end,
})

-- ── Cursorline follows focus ─────────────────────────────────────────
autocmd("WinEnter", {
	group = augroup,
	callback = function()
		if vim.bo.buftype ~= "terminal" then
			vim.opt_local.cursorline = true
		end
	end,
})
autocmd("WinLeave", {
	group = augroup,
	callback = function()
		if vim.bo.buftype ~= "terminal" then
			vim.opt_local.cursorline = false
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
autocmd("BufReadPost", {
	group = augroup,
	callback = function(ev)
		local path = vim.api.nvim_buf_get_name(ev.buf)
		if vim.bo[ev.buf].buftype ~= "" or path == "" then
			return
		end
		local ok, stat = pcall(vim.uv.fs_stat, path)
		if ok and stat and (stat.size / (1024 * 1024)) > 5 then
			vim.b[ev.buf].large_file = true
			vim.opt_local.foldmethod = "manual"
			vim.opt_local.foldenable = false
			vim.bo[ev.buf].syntax = ""
		end
	end,
})
