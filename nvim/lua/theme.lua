-- Theme configuration: vague colorscheme + custom highlight overrides
local M = {}

M.colors = {
	bg = "#141415",
	fg = "#cdcdcd",
	comment = "#606079",
	gutter = "#252530",
	border = "#252530",
	blue = "#6e94b2",
	purple = "#bb9dbd",
	green = "#7fa563",
	red = "#d8647e",
	yellow = "#f3be7c",
	cyan = "#b4d4cf",
	orange = "#e8b589",
}

function M.setup()
	local ok = pcall(vim.cmd.colorscheme, "vague")
	if not ok then
		vim.cmd.colorscheme("default")
		return
	end

	local c = M.colors
	local hl = function(name, opts)
		vim.api.nvim_set_hl(0, name, opts)
	end

	-- Define the Master Border Style
	hl("GlobalBorder", { fg = c.border, bg = c.bg })

	-- Link UI and Plugin Borders to the Master Style
	hl("FloatBorder", { link = "GlobalBorder" })
	hl("LspInfoBorder", { link = "GlobalBorder" })
	hl("FzfLuaBorder", { link = "GlobalBorder" })
	hl("FzfLuaPreviewBorder", { link = "GlobalBorder" })
	hl("FzfLuaPromptBorder", { link = "GlobalBorder" })
	hl("NoiceCmdlinePopupBorder", { link = "GlobalBorder" })
	hl("NoiceConfirmBorder", { link = "GlobalBorder" })
	hl("NoicePopupBorder", { link = "GlobalBorder" })
	hl("NoicePopupmenuBorder", { link = "GlobalBorder" })
	hl("MiniClueBorder", { link = "GlobalBorder" })
	hl("BlinkCmpMenuBorder", { link = "GlobalBorder" })
	hl("BlinkCmpDocBorder", { link = "GlobalBorder" })
	hl("BlinkCmpSignatureHelpBorder", { link = "GlobalBorder" })

	-- WinSeparator
	hl("WinSeparator", { fg = c.border })

	-- Floats and popups (Non-border highlights)
	hl("NormalFloat", { fg = c.border, bg = c.bg })
	hl("FloatTitle", { fg = c.blue, bg = c.bg, bold = true })
	hl("LspInfoTitle", { fg = c.blue, bg = c.bg, bold = true })
	hl("FzfLuaNormal", { bg = c.bg })
	hl("FzfLuaPreviewNormal", { bg = c.bg })
	hl("FzfLuaPromptNormal", { bg = c.bg })
	hl("NoiceCmdlinePopup", { bg = c.bg })
	hl("NoiceCmdlinePopupTitle", { fg = c.blue, bg = c.bg, bold = true })
	hl("NoiceConfirm", { bg = c.bg })
	hl("NoicePopup", { bg = c.bg })
	hl("NoicePopupmenu", { bg = c.bg })
	hl("NoicePopupmenuSelected", { bg = c.gutter, bold = true })
	hl("NoicePopupmenuMatch", { fg = c.blue, bold = true })
	hl("MiniClueNormal", { bg = c.bg })
	hl("MiniClueTitle", { fg = c.blue, bg = c.bg, bold = true })
	hl("MiniClueDescSingle", { fg = c.fg, bg = c.bg })
	hl("MiniClueDescGroup", { fg = c.comment, bg = c.bg })
	hl("MiniClueNextKey", { fg = c.blue, bg = c.bg, bold = true })
	hl("MiniClueNextKeyWithPostkeys", { fg = c.blue, bg = c.bg, bold = true })
	hl("MiniClueSeparator", { fg = c.border, bg = c.bg })

	-- Window chrome
	hl("StatusLine", { fg = c.fg, bg = c.bg })
	hl("StatusLineNC", { fg = c.comment, bg = c.bg })

	-- Cursor and selection
	hl("CursorLine", { bg = c.gutter })
	hl("CursorLineNr", { fg = c.blue, bold = true })
	hl("Visual", { bg = "#333738" })
	hl("LineNr", { fg = c.comment })

	-- Search
	hl("Search", { bg = "#2a3a4a", fg = c.blue })
	hl("IncSearch", { bg = c.blue, fg = c.bg, bold = true })
	hl("CurSearch", { bg = c.blue, fg = c.bg, bold = true })

	-- Diagnostics
	hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
	hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
	hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.cyan })
	hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.blue })
	hl("LspInlayHint", { fg = c.comment, italic = true })

	-- Completion (blink.cmp)
	hl("BlinkCmpMenu", { bg = c.bg })
	hl("BlinkCmpMenuSelection", { bg = c.gutter, bold = true })
	hl("BlinkCmpLabelMatch", { fg = c.blue, bold = true })
	hl("BlinkCmpDoc", { bg = c.bg })

	-- Treesitter context
	hl("TreesitterContext", { bg = c.bg })
	hl("TreesitterContextSeparator", { fg = c.gutter })
	hl("TreesitterContextLineNumber", { fg = c.comment, bg = c.bg })

	-- Indent guides
	hl("IblIndent", { fg = "#1a1a1f" })
	hl("IblScope", { fg = c.comment })

	-- Mini.nvim
	hl("MiniCursorword", { bg = c.gutter })
	hl("MiniCursorwordCurrent", { bg = c.gutter })
	hl("MiniTrailspace", { bg = "#3a1c28" })

	-- Folds
	hl("Folded", { fg = c.comment, bg = c.gutter })
	hl("FoldColumn", { fg = c.comment })

	-- Copilot
	hl("CopilotSuggestion", { fg = c.purple, italic = true })
end

return M
