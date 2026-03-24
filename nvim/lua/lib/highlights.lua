-- =============================================================================
-- Highlight Group Overrides
-- =============================================================================
local M = {}

-- Helper to lighten a hex color
local function lighten(hex, amount)
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)

	r = math.min(255, r + amount)
	g = math.min(255, g + amount)
	b = math.min(255, b + amount)

	return string.format("#%02x%02x%02x", r, g, b)
end

function M.apply()
	local hl = vim.api.nvim_set_hl
	local normal = vim.api.nvim_get_hl(0, { name = "Normal" })

	-- Fallback to a dark default if normal.bg is nil
	local base_bg = string.format("#%06x", normal.bg or 0x1a1b26)
	local float_bg = lighten(base_bg, 10)
	local border_color = "#4a4a5a"
	local selection_bg = "#2a2a30"

	hl(0, "Cursor", { bg = "#ff0000", fg = "#000000" })

	-- ── Float Windows ──────────────────────────────────────────────────────
	hl(0, "NormalFloat", { bg = float_bg, fg = normal.fg })
	hl(0, "FloatBorder", { bg = float_bg, fg = border_color })
	hl(0, "FzfLuaNormal", { bg = float_bg, fg = normal.fg })
	hl(0, "FzfLuaBorder", { bg = float_bg, fg = border_color })

	-- ── Completion Menu (Legacy/Standard) ──────────────────────────────────
	hl(0, "Pmenu", { bg = float_bg, fg = normal.fg })
	hl(0, "PmenuSel", { bg = selection_bg, fg = normal.fg })
	hl(0, "PmenuSbar", { bg = "#1a1a1c" })
	hl(0, "PmenuThumb", { bg = "#4a4a5a" })

	-- ── blink.cmp ──────────────────────────────────────────────────────────
	-- Main Menu
	hl(0, "BlinkCmpMenu", { bg = float_bg, fg = normal.fg })
	hl(0, "BlinkCmpMenuBorder", { bg = float_bg, fg = border_color })
	hl(0, "BlinkCmpMenuSelection", { bg = selection_bg, fg = normal.fg, bold = true })

	-- Documentation and Signature Help
	hl(0, "BlinkCmpDoc", { bg = float_bg, fg = normal.fg })
	hl(0, "BlinkCmpDocBorder", { bg = float_bg, fg = border_color })
	hl(0, "BlinkCmpSignatureHelp", { bg = float_bg, fg = normal.fg })
	hl(0, "BlinkCmpSignatureHelpBorder", { bg = float_bg, fg = border_color })

	-- Item details
	hl(0, "BlinkCmpLabel", { fg = normal.fg })
	hl(0, "BlinkCmpLabelMatch", { fg = "#89b4fa", bold = true }) -- Highlight matching characters
	hl(0, "BlinkCmpGhostText", { fg = "#505060", italic = true })

	-- Kind Icons (Optional: maps icons to specific colors)
	hl(0, "BlinkCmpKindSnippet", { fg = "#f38ba8" })
	hl(0, "BlinkCmpKindKeyword", { fg = "#cba6f7" })
	hl(0, "BlinkCmpKindText", { fg = "#a6e3a1" })

	-- ── Diagnostics ────────────────────────────────────────────────────────
	hl(0, "DiagnosticLineError", { bg = "#2a1720" })
	hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
	hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
	hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

	-- ── Copilot ────────────────────────────────────────────────────────────
	hl(0, "CopilotSuggestion", { fg = "#708090", bg = "#1a1f2e", italic = true, blend = 80 })

	-- ── Neogit ─────────────────────────────────────────────────────────────
	hl(0, "NeogitPopupBorder", { bg = float_bg, fg = border_color })
	hl(0, "NeogitFloatBorder", { bg = float_bg, fg = border_color })
	hl(0, "NeogitSectionHeader", { fg = "#6e94b2", bold = true })
	hl(0, "NeogitUnstagedChanges", { fg = "#d8647e" })
	hl(0, "NeogitStagedChanges", { fg = "#7fa563" })

	-- ── Misc ───────────────────────────────────────────────────────────────
	hl(0, "MiniTrailspace", { bg = "#3a1c28" })
end

return M
