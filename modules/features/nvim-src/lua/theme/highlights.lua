-- Highlight groups for the palette in theme/init.lua. Pure data: each entry is
-- a group name and its attributes.
local M = {}
local function hl(name, opts)
	vim.api.nvim_set_hl(0, name, opts)
end
--- @param c table Palette from theme/init.lua
--- @param blend fun(fg: string, bg: string, alpha: number): string
function M.set(c, blend)
	local separator = blend(c.fg, c.bg, 0.12)
	local indent = blend(c.comment, c.bg, 0.35)
	-- Flat editor-bg groups
	for _, g in ipairs({
		"NormalNC",
		"SignColumn",
		"StatusLine",
		"StatusLineNC",
		"WinBar",
		"WinBarNC",
		"MsgArea",
		"MsgSeparator",
		"PmenuSbar",
		"PmenuThumb",
		"TreesitterContext",
		"TreesitterContextLineNumber",
		"TabLine",
		"TabLineFill",
		"OilNormal",
		"OilFile",
	}) do
		hl(g, { link = "Normal" })
	end
	-- Float groups (same bg as editor, flat look)
	hl("NormalFloat", { link = "Normal" })
	for _, g in ipairs({
		"Pmenu",
		"BlinkCmpMenu",
		"BlinkCmpDoc",
		"BlinkCmpSignatureHelp",
		"FzfLuaNormal",
		"FzfLuaPreviewNormal",
		"FzfLuaPromptNormal",
		"FzfLuaHelpNormal",
		"MiniClueNormal",
	}) do
		hl(g, { link = "NormalFloat" })
	end
	-- Cursor
	hl("CursorLine", { bg = c.bgSubtle })
	hl("CursorLineNr", { fg = blend(c.blue, c.fg, 0.7), bold = true })
	hl("CursorColumn", { bg = c.bgSubtle })
	hl("CursorLineSign", { link = "SignColumn" })
	hl("CursorLineFold", { link = "FoldColumn" })
	-- Selection and search
	hl("Visual", { bg = c.selection })
	hl("VisualNOS", { link = "Visual" })
	hl("Search", { bg = c.search })
	hl("IncSearch", { fg = c.bg, bg = c.blue })
	hl("CurSearch", { link = "IncSearch" })
	hl("Substitute", { bg = blend(c.green, c.bg, 0.15) })
	hl("MatchParen", { fg = c.blue, bold = true, bg = c.selection })
	-- Non-text
	hl("NonText", { fg = blend(c.comment, c.bg, 0.3) })
	hl("Whitespace", { fg = blend(c.comment, c.bg, 0.15) })
	hl("Conceal", { fg = c.comment })
	hl("EndOfBuffer", { fg = c.bg })
	-- Line numbers
	hl("LineNr", { fg = c.comment, bg = c.bg })
	hl("LineNrAbove", { fg = c.comment })
	hl("LineNrBelow", { fg = c.comment })
	-- Separators, borders and titles
	hl("WinSeparator", { fg = separator })
	hl("GlobalBorder", { fg = c.border })
	for _, g in ipairs({
		"FloatBorder",
		"LspInfoBorder",
		"FzfLuaBorder",
		"FzfLuaPreviewBorder",
		"FzfLuaPromptBorder",
		"FzfLuaHelpBorder",
		"MiniClueBorder",
		"MiniClueSeparator",
		"BlinkCmpMenuBorder",
		"BlinkCmpDocBorder",
		"BlinkCmpSignatureHelpBorder",
		"BlinkCmpScrollBarThumb",
	}) do
		hl(g, { link = "GlobalBorder" })
	end
	hl("FloatTitle", { fg = c.blue, bold = true })
	for _, g in ipairs({ "LspInfoTitle", "FzfLuaTitle", "MiniClueTitle" }) do
		hl(g, { link = "FloatTitle" })
	end
	hl("FloatFooter", { fg = c.comment })
	-- FzfLua
	hl("FzfLuaScrollFloatEmpty", { fg = c.comment })
	hl("FzfLuaScrollFloatFull", { fg = c.blue })
	hl("FzfLuaHeaderText", { fg = c.comment })
	hl("FzfLuaHeaderBind", { fg = c.blue })
	hl("FzfLuaPath", { fg = c.comment })
	hl("FzfLuaDirPart", { fg = c.blue })
	hl("FzfLuaFilePart", { fg = c.fg })
	-- Mini.clue
	hl("MiniClueDescGroup", { fg = c.comment })
	hl("MiniClueNextKey", { fg = c.blue, bold = true })
	hl("MiniClueNextKeyWithPostkeys", { fg = c.blue, bold = true })
	-- Blink.cmp
	hl("BlinkCmpMenuSelection", { fg = c.fg, bg = c.selection, bold = true })
	hl("BlinkCmpLabelMatch", { fg = c.blue, bold = true })
	hl("BlinkCmpLabelDetail", { fg = c.comment, italic = true })
	hl("BlinkCmpLabelDescription", { fg = c.comment })
	hl("BlinkCmpSource", { fg = c.comment })
	hl("BlinkCmpKind", { fg = c.comment })
	hl("BlinkCmpGhostText", { fg = c.comment })
	hl("BlinkCmpSignatureHelpActiveParameter", { fg = c.blue, bold = true })
	hl("BlinkCmpScrollBarGutter", { fg = c.bgSubtle })
	local kind_colours = {
		Field = c.purple,
		Variable = c.fg,
		Function = c.blue,
		Method = c.blue,
		Class = c.orange,
		Interface = c.green,
		Keyword = c.purple,
		Snippet = c.cyan,
		Text = c.comment,
		Struct = c.orange,
		TypeParameter = c.cyan,
		Enum = c.green,
		EnumMember = c.yellow,
		Property = c.fg,
		Constant = c.orange,
		Module = c.purple,
		Unit = c.orange,
		Value = c.fg,
		Reference = c.cyan,
		Color = c.green,
		File = c.blue,
		Folder = c.blue,
		Event = c.orange,
		Constructor = c.orange,
	}
	for kind, colour in pairs(kind_colours) do
		hl("BlinkCmpKind" .. kind, { fg = colour })
	end
	-- Pmenu
	hl("PmenuSel", { fg = c.fg, bg = c.selection, bold = true })
	hl("PmenuKind", { fg = c.comment })
	hl("PmenuKindSel", { fg = c.blue })
	hl("PmenuMatch", { fg = c.blue, bold = true })
	hl("PmenuMatchSel", { fg = c.blue, bold = true })
	hl("PmenuExtra", { fg = c.comment })
	-- Diagnostics
	hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
	hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
	hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.cyan })
	hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.blue })
	hl("DiagnosticUnnecessary", { underdotted = true, sp = c.comment })
	hl("DiagnosticSignError", { fg = c.red, bg = c.bg })
	hl("DiagnosticSignWarn", { fg = c.yellow, bg = c.bg })
	hl("DiagnosticSignHint", { fg = c.cyan, bg = c.bg })
	hl("DiagnosticSignInfo", { fg = c.blue, bg = c.bg })
	hl("DiagnosticSignOk", { fg = c.green, bg = c.bg })
	hl("DiagnosticVirtualTextError", { fg = c.red, bg = blend(c.red, c.bg, 0.10) })
	hl("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = blend(c.yellow, c.bg, 0.10) })
	hl("DiagnosticVirtualTextHint", { fg = c.cyan, bg = blend(c.cyan, c.bg, 0.08) })
	hl("DiagnosticVirtualTextInfo", { fg = c.blue, bg = blend(c.blue, c.bg, 0.08) })
	hl("DiagnosticDeprecated", { strikethrough = true, sp = c.comment })
	hl("DiagnosticFloatingError", { fg = c.red })
	hl("DiagnosticFloatingWarn", { fg = c.yellow })
	hl("DiagnosticFloatingHint", { fg = c.cyan })
	hl("DiagnosticFloatingInfo", { fg = c.blue })
	-- LSP
	hl("LspInlayHint", { fg = c.comment, bg = blend(c.fg, c.bg, 0.05), italic = true })
	hl("LspReferenceText", { bg = c.selection })
	hl("LspReferenceRead", { bg = c.selection })
	hl("LspReferenceWrite", { bg = c.selection })
	hl("LspCodeLens", { fg = c.comment })
	hl("LspCodeLensSeparator", { fg = c.comment })
	hl("LspSignatureActiveParameter", { fg = c.blue, bold = true })
	-- Semantic tokens
	hl("@lsp.type.class", { fg = c.orange })
	hl("@lsp.type.function", { fg = c.blue })
	hl("@lsp.type.method", { fg = c.blue })
	hl("@lsp.type.parameter", { fg = c.fg, italic = true })
	hl("@lsp.type.variable", { fg = c.fg })
	hl("@lsp.type.property", { fg = c.fg })
	hl("@lsp.type.enumMember", { fg = c.yellow })
	hl("@lsp.type.keyword", { fg = c.purple })
	hl("@lsp.type.comment", { fg = c.comment, italic = true })
	-- Diff and git
	hl("DiffAdd", { bg = blend(c.green, c.bg, 0.12) })
	hl("DiffDelete", { bg = blend(c.red, c.bg, 0.12) })
	hl("DiffChange", { bg = blend(c.yellow, c.bg, 0.12) })
	hl("DiffText", { bg = blend(c.blue, c.bg, 0.2) })
	hl("DiffAddGutter", { fg = c.green, bg = c.bg })
	hl("DiffDeleteGutter", { fg = c.red, bg = c.bg })
	hl("DiffChangeGutter", { fg = c.yellow, bg = c.bg })
	hl("GitSignsAdd", { fg = c.green })
	hl("GitSignsChange", { fg = c.yellow })
	hl("GitSignsDelete", { fg = c.red })
	hl("GitSignsCurrentLineBlame", { fg = c.comment, italic = true })
	-- UI elements
	hl("TabLineSel", { bg = c.bg, fg = c.fg, bold = true })
	hl("QuickFixLine", { bg = c.selection, bold = true })
	hl("ColorColumn", { bg = c.bgSubtle })
	hl("CmdlineCursor", { fg = c.bg, bg = c.blue })
	-- Spelling
	hl("SpellBad", { undercurl = true, sp = c.red })
	hl("SpellCap", { undercurl = true, sp = c.yellow })
	hl("SpellRare", { undercurl = true, sp = c.cyan })
	hl("SpellLocal", { undercurl = true, sp = c.blue })
	-- Folding
	hl("Folded", { fg = blend(c.blue, c.comment, 0.4), bg = blend(c.blue, c.bg, 0.07) })
	hl("FoldColumn", { fg = c.comment, bg = c.bg })
	hl("TreesitterContextSeparator", { fg = separator })
	-- Copilot
	hl("CopilotSuggestion", { fg = c.purple, italic = true })
	hl("CopilotPanelLabel", { fg = c.blue, bold = true })
	hl("CopilotPanelSelected", { fg = c.blue, bg = c.selection, bold = true })
	-- Mini modules
	hl("MiniHipatternsFixme", { fg = c.bg, bg = c.red, bold = true })
	hl("MiniHipatternsTodo", { fg = c.bg, bg = c.orange, bold = true })
	hl("MiniHipatternsNote", { fg = c.bg, bg = c.blue, bold = true })
	hl("MiniHipatternsHack", { fg = c.bg, bg = c.purple, bold = true })
	hl("MiniCursorword", { bg = c.selection })
	hl("MiniCursorwordCurrent", { bg = c.selection })
	-- Oil
	hl("OilDir", { fg = c.blue, bold = true })
	hl("OilDirIcon", { fg = c.blue })
	-- Statusline
	hl("StlModeN", { fg = c.bg, bg = c.blue, bold = true })
	hl("StlModeI", { fg = c.bg, bg = c.green, bold = true })
	hl("StlModeV", { fg = c.bg, bg = c.purple, bold = true })
	hl("StlModeC", { fg = c.bg, bg = c.yellow, bold = true })
	hl("StlModeR", { fg = c.bg, bg = c.red, bold = true })
	hl("StlModeT", { fg = c.bg, bg = c.cyan, bold = true })
	hl("StlModeS", { fg = c.bg, bg = c.orange, bold = true })
	hl("StlGit", { fg = blend(c.blue, c.comment, 0.5) })
	hl("StlDiag", { fg = c.comment })
	hl("StlFile", { fg = c.fg })
	hl("StlLSP", { fg = blend(c.comment, c.bg, 0.7) })
	hl("StlFT", { fg = c.comment })
	hl("StlPos", { fg = blend(c.comment, c.bg, 0.6) })
	-- Indent guides (indent-blankline)
	hl("IblIndent", { fg = indent })
	hl("IblScope", { fg = blend(c.blue, c.comment, 0.3) })
end
return M
