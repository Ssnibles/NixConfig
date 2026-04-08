-- Theme configuration: vague colorscheme + custom highlight overrides
local M = {}

M.colors = {
	bg = "#141415",
	bg_float = "#1c1c24",
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

	-- Floats and popups
	hl("NormalFloat", { bg = c.bg_float })
	hl("FloatBorder", { fg = c.border, bg = c.bg_float })
	hl("FloatTitle", { fg = c.blue, bg = c.bg_float, bold = true })
	hl("LspInfoBorder", { fg = c.border, bg = c.bg_float })
	hl("LspInfoTitle", { fg = c.blue, bg = c.bg_float, bold = true })
	hl("FzfLuaNormal", { bg = c.bg })
	hl("FzfLuaBorder", { fg = c.border, bg = c.bg })
	hl("FzfLuaPreviewNormal", { bg = c.bg })
	hl("FzfLuaPreviewBorder", { fg = c.border, bg = c.bg })
	hl("FzfLuaPromptNormal", { bg = c.bg })
	hl("FzfLuaPromptBorder", { fg = c.border, bg = c.bg })
	hl("NoiceCmdlinePopup", { bg = c.bg_float })
	hl("NoiceCmdlinePopupBorder", { fg = c.border, bg = c.bg_float })
	hl("NoiceCmdlinePopupTitle", { fg = c.blue, bg = c.bg_float, bold = true })
	hl("NoiceConfirm", { bg = c.bg_float })
	hl("NoiceConfirmBorder", { fg = c.border, bg = c.bg_float })
	hl("NoicePopup", { bg = c.bg_float })
	hl("NoicePopupBorder", { fg = c.border, bg = c.bg_float })
	hl("NoicePopupmenu", { bg = c.bg_float })
	hl("NoicePopupmenuBorder", { fg = c.border, bg = c.bg_float })
	hl("MiniClueNormal", { bg = c.bg_float })
	hl("MiniClueBorder", { fg = c.border, bg = c.bg_float })

	-- Window chrome
	hl("WinSeparator", { fg = c.border })
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
	hl("BlinkCmpMenuBorder", { fg = c.border, bg = c.bg })
	hl("BlinkCmpMenuSelection", { bg = c.gutter, bold = true })
	hl("BlinkCmpLabelMatch", { fg = c.blue, bold = true })
	hl("BlinkCmpDoc", { bg = c.bg })
	hl("BlinkCmpDocBorder", { fg = c.border, bg = c.bg })

	-- Treesitter context
	hl("TreesitterContext", { bg = c.gutter })
	hl("TreesitterContextSeparator", { fg = c.comment })

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
