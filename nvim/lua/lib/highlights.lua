-- =============================================================================
-- Highlight Group Overrides
-- =============================================================================
-- Centralized highlight definitions for consistent UI appearance.
-- Only override what's necessary - let colorscheme handle the rest.
local M = {}

function M.apply()
	local hl = vim.api.nvim_set_hl
	local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	local border_color = "#4a4a5a"

	-- ── Cursor & Selection ─────────────────────────────────────────────────
	-- Don't override foreground on CursorLine - only background
	hl(0, "Cursor", { bg = "#6e94b2", fg = "#141415" })
	hl(0, "CursorLine", { bg = "#1a1a1c", blend = 0 })
	hl(0, "CursorColumn", { bg = "#1a1a1c" })
	hl(0, "Visual", { bg = "#2a2a35" })

	-- ── Float Windows ──────────────────────────────────────────────────────
	hl(0, "FloatBorder", { bg = normal.bg, fg = border_color })
	hl(0, "NormalFloat", { bg = normal.bg, fg = normal.fg })
	hl(0, "FzfLuaBorder", { bg = normal.bg, fg = border_color })
	hl(0, "FzfLuaNormal", { bg = normal.bg, fg = normal.fg })

	-- ── Completion Menu ────────────────────────────────────────────────────
	hl(0, "Pmenu", { bg = normal.bg, fg = normal.fg })
	hl(0, "PmenuSel", { bg = "#2a2a30", fg = normal.fg })
	hl(0, "PmenuSbar", { bg = "#1a1a1c" })
	hl(0, "PmenuThumb", { bg = "#4a4a5a" })

	-- ── Diagnostics ────────────────────────────────────────────────────────
	-- Subtle background tints for lines with diagnostics
	hl(0, "DiagnosticLineError", { bg = "#2a1720" })
	hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
	hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
	hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

	-- ── Indent Guides ──────────────────────────────────────────────────────
	hl(0, "IblIndent", { fg = "#2a2a30" })
	hl(0, "IblScope", { fg = "#404050" })

	-- ── blink.cmp ──────────────────────────────────────────────────────────
	hl(0, "BlinkMenuNormal", { bg = normal.bg, fg = normal.fg })
	hl(0, "BlinkMenuBorder", { bg = normal.bg, fg = border_color })
	hl(0, "BlinkMenuSel", { bg = "#2a2a30", fg = normal.fg })

	-- ── Copilot ────────────────────────────────────────────────────────────
	hl(0, "CopilotSuggestion", { fg = "#606079", italic = true })

	-- ── Misc ───────────────────────────────────────────────────────────────
	hl(0, "MiniTrailspace", { bg = "#3a1c28" })
end

return M
