-- ============================================================================
-- AUTOCOMMANDS
-- All autocommands live in a single named group so they can be cleanly
-- cleared and re-applied if this file is sourced more than once (e.g. during
-- hot-reload / config development).
-- ============================================================================
local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- ============================================================================
-- YANK HIGHLIGHT
-- Briefly flash the yanked region after a yank operation.
-- ============================================================================
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- ============================================================================
-- DIAGNOSTIC LINE NUMBER HIGHLIGHTS
-- Colour the line number (and line background) of any line that has a
-- diagnostic, using the highest-severity colour on that line.
-- This gives you at-a-glance diagnostic awareness without covering code.
--
-- sign  → DiagnosticSign*   — built-in groups, colours the gutter number
-- line  → DiagnosticLine*   — custom groups defined in plugins/highlights.lua
--                             using explicit bg tints so the theme can't
--                             override them the way it does DiagnosticVirtualText*.
-- ============================================================================

local diag_ns = vim.api.nvim_create_namespace("diag_linenum_hl")

-- Map diagnostic severity → highlight groups for the number and line.
local severity_hl = {
	[vim.diagnostic.severity.ERROR] = { sign = "DiagnosticSignError", line = "DiagnosticLineError" },
	[vim.diagnostic.severity.WARN] = { sign = "DiagnosticSignWarn", line = "DiagnosticLineWarn" },
	[vim.diagnostic.severity.INFO] = { sign = "DiagnosticSignInfo", line = "DiagnosticLineInfo" },
	[vim.diagnostic.severity.HINT] = { sign = "DiagnosticSignHint", line = "DiagnosticLineHint" },
}

local function update_diag_linenum_hl(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	-- Clear previous extmarks for this namespace.
	vim.api.nvim_buf_clear_namespace(bufnr, diag_ns, 0, -1)

	-- Build a table of line → highest severity for that line.
	local line_severity = {}
	for _, diag in ipairs(vim.diagnostic.get(bufnr)) do
		-- Lower severity value = higher priority (ERROR = 1, HINT = 4).
		if not line_severity[diag.lnum] or diag.severity < line_severity[diag.lnum] then
			line_severity[diag.lnum] = diag.severity
		end
	end

	-- Apply extmarks to colour the line number and background.
	for line, severity in pairs(line_severity) do
		local hl = severity_hl[severity]
		vim.api.nvim_buf_set_extmark(bufnr, diag_ns, line, 0, {
			number_hl_group = hl.sign,
			line_hl_group = hl.line,
		})
	end
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
	group = group,
	callback = function(ev)
		update_diag_linenum_hl(ev.buf)
	end,
})

-- ============================================================================
-- RESTORE CURSOR POSITION
-- When reopening a file, jump back to where the cursor was when you last
-- closed it (stored in the ShaDa file via the `"` mark).
-- ============================================================================
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		-- Only restore if the saved position is within the file's current bounds.
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- ============================================================================
-- TRIM TRAILING WHITESPACE ON SAVE
-- Applies to all buffers. Preserves cursor position.
-- ============================================================================
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group,
	callback = function()
		local pos = vim.api.nvim_win_get_cursor(0)
		vim.cmd([[%s/\s\+$//e]])
		vim.api.nvim_win_set_cursor(0, pos)
	end,
})
