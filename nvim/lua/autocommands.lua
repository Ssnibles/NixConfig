-- =============================================================================
-- Autocommand Configuration
-- =============================================================================
-- Event-driven behaviors for yank highlighting, cursor restoration,
-- whitespace trimming, and diagnostic display.
local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- ── Yank Highlight ─────────────────────────────────────────────────────────
-- Flash highlight on yanked text for visual feedback
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- ── Restore Cursor Position ────────────────────────────────────────────────
-- Return to last edit position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- ── Trim Trailing Whitespace ───────────────────────────────────────────────
-- Remove trailing whitespace on save using mini.trailspace with fallback
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group,
	callback = function()
		local ok, ts = pcall(require, "mini.trailspace")
		if ok then
			ts.trim()
			ts.trim_last_lines()
		else
			-- Fallback: manual trim while preserving cursor position
			local pos = vim.api.nvim_win_get_cursor(0)
			vim.cmd([[%s/\s\+$//e]])
			vim.api.nvim_win_set_cursor(0, pos)
		end
	end,
})

-- ── Close Help and Utility Buffers ─────────────────────────────────────────
-- Press 'q' to close read-only and utility buffers
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "oil" },
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Close window" })
	end,
})

-- ── Auto-Resize Splits ─────────────────────────────────────────────────────
-- Equalize window sizes when terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- ── Strip Carriage Returns ─────────────────────────────────────────────────
-- Remove Windows-style line endings on file open
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function()
		if vim.bo.fileformat == "dos" then
			vim.cmd([[silent! %s/\r//g]])
		end
	end,
})

-- ── Disable Auto-Comment ───────────────────────────────────────────────────
-- Prevent automatic comment continuation on new lines
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- ── Prose Filetypes ────────────────────────────────────────────────────────
-- Enable spell check and wrapping for text files
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
	end,
})

-- ── Diagnostic Line Highlights ─────────────────────────────────────────────
-- Apply background tint to lines with diagnostics for visibility
local diag_ns = vim.api.nvim_create_namespace("diag_linenum_hl")
local severity_hl = {
	[vim.diagnostic.severity.ERROR] = { sign = "DiagnosticSignError", line = "DiagnosticLineError" },
	[vim.diagnostic.severity.WARN] = { sign = "DiagnosticSignWarn", line = "DiagnosticLineWarn" },
	[vim.diagnostic.severity.INFO] = { sign = "DiagnosticSignInfo", line = "DiagnosticLineInfo" },
	[vim.diagnostic.severity.HINT] = { sign = "DiagnosticSignHint", line = "DiagnosticLineHint" },
}

local function update_diag_hl(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, diag_ns, 0, -1)
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
	callback = function(ev)
		pcall(update_diag_hl, ev.buf)
	end,
})
