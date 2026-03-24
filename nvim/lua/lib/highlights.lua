-- =============================================================================
-- Highlight Group Overrides
-- =============================================================================
-- Centralized highlight definitions for consistent UI appearance.
-- Only override what's necessary - let colorscheme handle the rest.
-- Applied after colorscheme loads to ensure proper inheritance.
-- =============================================================================
local M = {}
function M.apply()
	local hl = vim.api.nvim_set_hl
	local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	local border_color = "#4a4a5a"

	hl(0, "Cursor", { bg = "#ff0000", fg = "#000000" })

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
	hl(0, "DiagnosticLineError", { bg = "#2a1720" })
	hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
	hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
	hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

	-- ── blink.cmp ──────────────────────────────────────────────────────────
	hl(0, "BlinkMenuNormal", { bg = normal.bg, fg = normal.fg })
	hl(0, "BlinkMenuBorder", { bg = normal.bg, fg = border_color })
	hl(0, "BlinkMenuSel", { bg = "#2a2a30", fg = normal.fg })
	hl(0, "BlinkCmpGhostText", { fg = "#505060", bg = "NONE", italic = true })

	-- ── Copilot ────────────────────────────────────────────────────────────
	hl(0, "CopilotSuggestion", { fg = "#708090", bg = "#1a1f2e", italic = true, blend = 80 })

	-- ── Neogit ─────────────────────────────────────────────────────────────
	hl(0, "NeogitPopupBorder", { bg = normal.bg, fg = border_color })
	hl(0, "NeogitFloatBorder", { bg = normal.bg, fg = border_color })
	hl(0, "NeogitSectionHeader", { fg = "#6e94b2", bold = true })
	hl(0, "NeogitUnstagedChanges", { fg = "#d8647e" })
	hl(0, "NeogitStagedChanges", { fg = "#7fa563" })

	-- ── Misc ───────────────────────────────────────────────────────────────
	hl(0, "MiniTrailspace", { bg = "#3a1c28" })
end
return M
