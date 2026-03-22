-- =============================================================================
-- Autocommands Configuration
-- =============================================================================
-- Event-driven behaviors for file operations, diagnostics, and UI enhancements.
-- All autocommands are grouped under "UserConfig" for easy management and
-- so :augroup UserConfig can be inspected or cleared during development.
-- =============================================================================

local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- ── Yank Highlight ─────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	desc = "Flash yanked region",
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- ── Restore Cursor Position ────────────────────────────────────────────────
-- Jump back to where the cursor was when the file was last closed
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	desc = "Restore cursor to last known position",
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- ── Trim Trailing Whitespace ───────────────────────────────────────────────
-- Uses mini.trailspace when available; silently skips otherwise
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group,
	desc = "Strip trailing whitespace on save",
	callback = function()
		local ok, ts = pcall(require, "mini.trailspace")
		if ok then
			ts.trim()
			ts.trim_last_lines()
		end
	end,
})

-- ── Close Utility Buffers with 'q' ─────────────────────────────────────────
-- Lets you dismiss transient windows without reaching for :q<CR>
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Map q to close for utility filetypes",
	pattern = {
		"help",
		"man",
		"qf",
		"lspinfo",
		"checkhealth",
		"notify",
		"oil",
		"noice", -- noice message log popup
		"copilot-panel", -- Copilot suggestions panel
	},
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Close window" })
	end,
})

-- ── Auto-resize Splits ─────────────────────────────────────────────────────
-- Keep split proportions sane when the terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	desc = "Equalise splits on terminal resize",
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- ── Strip Carriage Returns (DOS → Unix) ────────────────────────────────────
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	desc = "Remove \\r from DOS-format files on read",
	callback = function()
		if vim.bo.fileformat == "dos" then
			vim.cmd([[silent! %s/\r//g]])
		end
	end,
})

-- ── Disable Auto-comment on New Lines ──────────────────────────────────────
-- Neovim's default formatoptions continue comment leaders on <Enter>/<o>/<O>
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Disable automatic comment continuation",
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- ── Prose Filetypes (spell check + wrap) ───────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Enable spell and wrap for prose filetypes",
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
	end,
})

-- ── Diagnostic Line Highlights ─────────────────────────────────────────────
-- Colours the line number and line background of each diagnostic according
-- to its severity. Uses extmarks so it plays nicely with statuscol.
local diag_ns = vim.api.nvim_create_namespace("diag_linenum_hl")
local severity_hl = {
	[vim.diagnostic.severity.ERROR] = { sign = "DiagnosticSignError", line = "DiagnosticLineError" },
	[vim.diagnostic.severity.WARN] = { sign = "DiagnosticSignWarn", line = "DiagnosticLineWarn" },
	[vim.diagnostic.severity.INFO] = { sign = "DiagnosticSignInfo", line = "DiagnosticLineInfo" },
	[vim.diagnostic.severity.HINT] = { sign = "DiagnosticSignHint", line = "DiagnosticLineHint" },
}

local function update_diag_hl(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, diag_ns, 0, -1)
	-- Collect worst (lowest severity value = highest priority) per line
	local worst = {}
	for _, d in ipairs(vim.diagnostic.get(bufnr)) do
		if not worst[d.lnum] or d.severity < worst[d.lnum] then
			worst[d.lnum] = d.severity
		end
	end
	for line, sev in pairs(worst) do
		local hl = severity_hl[sev]
		vim.api.nvim_buf_set_extmark(bufnr, diag_ns, line, 0, {
			number_hl_group = hl.sign,
			line_hl_group = hl.line,
		})
	end
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
	group = group,
	desc = "Refresh diagnostic line highlight extmarks",
	callback = function(ev)
		pcall(update_diag_hl, ev.buf)
	end,
})
