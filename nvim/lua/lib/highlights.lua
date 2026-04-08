-- =============================================================================
-- Custom Highlights for Vague Theme
-- =============================================================================
-- Additional highlight groups to enhance the vague colorscheme
-- Colors are consistent with the vague theme palette defined in fish.nix
-- =============================================================================
local M = {}

-- Vague theme color palette (for reference and consistency)
local colors = {
	bg = "#141415",
	bg_raised = "#1c1c24",
	fg = "#cdcdcd",
	fg_mid = "#878787",
	muted = "#606079",
	subtle = "#252530",
	blue = "#6e94b2",
	purple = "#bb9dbd",
	green = "#7fa563",
	red = "#d8647e",
	yellow = "#f3be7c",
	cyan = "#b4d4cf",
	orange = "#e8b589",
}

function M.apply()
	local hl = vim.api.nvim_set_hl

	-- ── Floating Windows & Borders ─────────────────────────────────────────
	hl(0, "NormalFloat", { bg = colors.bg_raised })
	hl(0, "FloatBorder", { fg = colors.subtle, bg = colors.bg_raised })
	hl(0, "FloatTitle", { fg = colors.blue, bg = colors.bg_raised, bold = true })

	-- ── Window Separators ─────────────────────────────────────────────────
	hl(0, "WinSeparator", { fg = colors.subtle, bg = "none" })
	hl(0, "VertSplit", { fg = colors.subtle, bg = "none" })

	-- ── Popup Menus ───────────────────────────────────────────────────────
	hl(0, "Pmenu", { fg = colors.fg, bg = colors.bg_raised })
	hl(0, "PmenuSel", { bg = colors.subtle, bold = true })
	hl(0, "PmenuSbar", { bg = colors.subtle })
	hl(0, "PmenuThumb", { bg = colors.muted })

	-- ── Statusline & Tabline ──────────────────────────────────────────────
	hl(0, "StatusLine", { fg = colors.fg, bg = colors.bg })
	hl(0, "StatusLineNC", { fg = colors.muted, bg = colors.bg })
	hl(0, "TabLine", { fg = colors.muted, bg = colors.bg })
	hl(0, "TabLineSel", { fg = colors.fg, bg = colors.subtle, bold = true })
	hl(0, "TabLineFill", { bg = colors.bg })

	-- ── Cursor & Selection ─────────────────────────────────────────────────
	hl(0, "CursorLine", { bg = colors.subtle })
	hl(0, "CursorLineNr", { fg = colors.blue, bold = true })
	hl(0, "Visual", { bg = "#333738" })

	-- ── LSP Inlay Hints ────────────────────────────────────────────────────
	hl(0, "LspInlayHint", { fg = colors.muted, italic = true })

	-- ── Diagnostics ────────────────────────────────────────────────────────
	hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = colors.red })
	hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = colors.yellow })
	hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = colors.cyan })
	hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = colors.blue })

	-- Subtle line backgrounds for diagnostics
	hl(0, "DiagnosticLineError", { bg = "#2a1720" })
	hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
	hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
	hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

	-- ── Completion Menu (Blink.cmp) ────────────────────────────────────────
	hl(0, "BlinkCmpMenu", { bg = colors.bg })
	hl(0, "BlinkCmpMenuBorder", { fg = colors.blue, bg = "none" })
	hl(0, "BlinkCmpMenuSelection", { bg = colors.subtle, bold = true })
	hl(0, "BlinkCmpLabel", { fg = colors.fg })
	hl(0, "BlinkCmpLabelMatch", { fg = colors.blue, bold = true })
	hl(0, "BlinkCmpDoc", { bg = colors.bg })
	hl(0, "BlinkCmpDocBorder", { fg = colors.blue, bg = "none" })
	hl(0, "BlinkCmpDocCursorLine", { bg = colors.subtle })

	-- Completion item kinds with semantic colors
	hl(0, "BlinkCmpKind", { bg = colors.bg })
	hl(0, "BlinkCmpKindSnippet", { fg = colors.purple, bg = colors.bg })
	hl(0, "BlinkCmpKindKeyword", { fg = colors.blue, bg = colors.bg })
	hl(0, "BlinkCmpKindText", { fg = colors.fg, bg = colors.bg })
	hl(0, "BlinkCmpKindFunction", { fg = colors.green, bg = colors.bg })
	hl(0, "BlinkCmpKindMethod", { fg = colors.green, bg = colors.bg })
	hl(0, "BlinkCmpKindVariable", { fg = colors.cyan, bg = colors.bg })
	hl(0, "BlinkCmpKindClass", { fg = colors.yellow, bg = colors.bg })
	hl(0, "BlinkCmpKindInterface", { fg = colors.yellow, bg = colors.bg })
	hl(0, "BlinkCmpKindModule", { fg = colors.orange, bg = colors.bg })

	-- ── GitHub Copilot ─────────────────────────────────────────────────────
	hl(0, "CopilotSuggestion", { fg = colors.muted, italic = true })

	-- ── Git Signs (Neogit) ─────────────────────────────────────────────────
	hl(0, "NeogitPopupBorder", { bg = colors.bg_raised, fg = colors.subtle })
	hl(0, "NeogitFloatBorder", { bg = colors.bg_raised, fg = colors.subtle })
	hl(0, "NeogitSectionHeader", { fg = colors.blue, bold = true })
	hl(0, "NeogitUnstagedChanges", { fg = colors.red })
	hl(0, "NeogitStagedChanges", { fg = colors.green })

	-- ── Treesitter Context ─────────────────────────────────────────────────
	hl(0, "TreesitterContext", { bg = colors.subtle })
	hl(0, "TreesitterContextLineNumber", { fg = colors.muted, bg = colors.subtle })
	hl(0, "TreesitterContextSeparator", { fg = colors.muted })

	-- ── Indent Guides ──────────────────────────────────────────────────────
	hl(0, "IblIndent", { fg = "#1a1a1f" })
	hl(0, "IblScope", { fg = colors.muted })

	-- ── Mini.nvim ──────────────────────────────────────────────────────────
	hl(0, "MiniCursorword", { bg = colors.subtle, underline = false })
	hl(0, "MiniCursorwordCurrent", { bg = colors.subtle, underline = false })
	hl(0, "MiniTrailspace", { bg = "#3a1c28" })

	-- ── Fold ───────────────────────────────────────────────────────────────
	hl(0, "Folded", { fg = colors.muted, bg = colors.subtle })
	hl(0, "FoldColumn", { fg = colors.muted, bg = "none" })

	-- ── Search ─────────────────────────────────────────────────────────────
	hl(0, "Search", { bg = "#2a3a4a", fg = colors.blue })
	hl(0, "IncSearch", { bg = colors.blue, fg = colors.bg, bold = true })
	hl(0, "CurSearch", { bg = colors.blue, fg = colors.bg, bold = true })

	-- ── StatusColumn ───────────────────────────────────────────────────────
	hl(0, "LineNr", { fg = colors.muted })
	hl(0, "SignColumn", { bg = "none" })

	-- ── Oil File Manager ───────────────────────────────────────────────────
	hl(0, "OilDir", { fg = colors.blue, bold = true })
	hl(0, "OilFile", { fg = colors.fg })
	hl(0, "OilHidden", { fg = colors.muted })
end

return M
