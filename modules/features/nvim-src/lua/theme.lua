local M = {}

M.colors = {
	bg = "#141415",
	fg = "#cdcdcd",
	comment = "#606079",
	bgSubtle = "#252530",
	gutter = "#252530",
	border = "#252530",
	blue = "#6e94b2",
	purple = "#bb9dbd",
	green = "#7fa563",
	red = "#d8647e",
	yellow = "#f3be7c",
	cyan = "#b4d4cf",
	orange = "#e8b589",
	magenta = "#c48282",
	selection = "#333738",
	search = "#2a3a4a",
}

local function blend(fg, bg, alpha)
	local function parse(hex)
		hex = hex:gsub("#", "")
		return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	end
	local r1, g1, b1 = parse(fg)
	local r2, g2, b2 = parse(bg)
	local r = math.floor(r1 * alpha + r2 * (1 - alpha) + 0.5)
	local g = math.floor(g1 * alpha + g2 * (1 - alpha) + 0.5)
	local b = math.floor(b1 * alpha + b2 * (1 - alpha) + 0.5)
	return string.format("#%02x%02x%02x", r, g, b)
end

function M.setup()
	local c = M.colors

	vim.o.background = "dark"

	require("mini.base16").setup({
		palette = {
			base00 = c.bg,
			base01 = c.bg,
			base02 = c.bg,
			base03 = c.comment,
			base04 = c.comment,
			base05 = c.fg,
			base06 = c.fg,
			base07 = c.fg,
			base08 = c.red,
			base09 = c.orange,
			base0A = c.yellow,
			base0B = c.green,
			base0C = c.cyan,
			base0D = c.blue,
			base0E = c.purple,
			base0F = c.magenta,
		},
	})

	local separator = blend(c.fg, c.bg, 0.06)
	local indent = blend(c.comment, c.bg, 0.35)

	local hl = function(name, opts)
		vim.api.nvim_set_hl(0, name, opts)
	end

	hl("Normal", { fg = c.fg, bg = c.bg })

	local flat_groups = {
		"NormalNC", "NormalFloat", "SignColumn", "FoldColumn",
		"StatusLine", "StatusLineNC", "WinBar", "WinBarNC",
		"MsgArea", "MsgSeparator", "Pmenu", "PmenuSbar", "PmenuThumb",
		"BlinkCmpMenu", "BlinkCmpDoc", "BlinkCmpSignatureHelp",
		"FzfLuaNormal", "FzfLuaPreviewNormal", "FzfLuaPromptNormal", "FzfLuaCursor",
		"FzfLuaHelpNormal", "FzfLuaHelpBorder",
		"MiniClueNormal", "MiniAnimateNormalFloat",
		"TreesitterContext", "TreesitterContextLineNumber",
		"DAPUINormal", "DAPUIFloatNormal",
		"TabLine", "TabLineFill", "OilNormal",
	}
	for _, g in ipairs(flat_groups) do
		hl(g, { link = "Normal" })
	end

	hl("CursorLine", { bg = c.bgSubtle })
	hl("CursorLineNr", { fg = c.blue, bg = c.bgSubtle, bold = true })
	hl("CursorColumn", { bg = c.bgSubtle })
	hl("CursorLineSign", { link = "CursorLine" })
	hl("CursorLineFold", { link = "CursorLine" })

	hl("Visual", { bg = c.selection })
	hl("VisualNOS", { link = "Visual" })

	hl("Search", { bg = c.search })
	hl("IncSearch", { fg = c.bg, bg = c.blue })
	hl("CurSearch", { link = "IncSearch" })
	hl("Substitute", { bg = blend(c.green, c.bg, 0.15) })

	hl("MatchParen", { fg = c.blue, bold = true, bg = c.selection })

	hl("NonText", { fg = blend(c.comment, c.bg, 0.3) })
	hl("Whitespace", { fg = blend(c.comment, c.bg, 0.15) })
	hl("Conceal", { fg = c.comment })
	hl("EndOfBuffer", { fg = c.bg })

	hl("LineNr", { fg = c.comment, bg = c.bg })
	hl("LineNrAbove", { fg = c.comment })
	hl("LineNrBelow", { fg = c.comment })

	hl("WinSeparator", { fg = separator })

	hl("GlobalBorder", { fg = c.border })
	hl("FloatBorder", { link = "GlobalBorder" })
	hl("FloatTitle", { fg = c.blue, bold = true })
	hl("FloatFooter", { fg = c.comment })

	hl("LspInfoBorder", { link = "GlobalBorder" })
	hl("LspInfoTitle", { fg = c.blue, bold = true })

	hl("FzfLuaBorder", { link = "GlobalBorder" })
	hl("FzfLuaPreviewBorder", { link = "GlobalBorder" })
	hl("FzfLuaPromptBorder", { link = "GlobalBorder" })
	hl("FzfLuaTitle", { fg = c.blue, bold = true })
	hl("FzfLuaScrollFloatEmpty", { fg = c.comment })
	hl("FzfLuaScrollFloatFull", { fg = c.blue })
	hl("FzfLuaHeaderText", { fg = c.comment })
	hl("FzfLuaHeaderBind", { fg = c.blue })
	hl("FzfLuaPath", { fg = c.comment })
	hl("FzfLuaDirPart", { fg = c.blue })
	hl("FzfLuaFilePart", { fg = c.fg })

	hl("MiniClueBorder", { link = "GlobalBorder" })
	hl("MiniClueTitle", { fg = c.blue, bold = true })
	hl("MiniClueDescGroup", { fg = c.comment })
	hl("MiniClueNextKey", { fg = c.blue, bold = true })
	hl("MiniClueNextKeyWithPostkeys", { fg = c.blue, bold = true })
	hl("MiniClueSeparator", { fg = c.border })

	hl("BlinkCmpMenuBorder", { link = "GlobalBorder" })
	hl("BlinkCmpDocBorder", { link = "GlobalBorder" })
	hl("BlinkCmpSignatureHelpBorder", { link = "GlobalBorder" })

	hl("BlinkCmpMenuSelection", { fg = c.fg, bg = c.selection, bold = true })
	hl("BlinkCmpLabelMatch", { fg = c.blue, bold = true })
	hl("BlinkCmpLabelDetail", { fg = c.comment, italic = true })
	hl("BlinkCmpLabelDescription", { fg = c.comment })
	hl("BlinkCmpSource", { fg = c.comment })
	hl("BlinkCmpKind", { fg = c.comment })
	hl("BlinkCmpGhostText", { fg = c.comment })

	local kindHls = {
		Field = c.purple, Variable = c.fg, Function = c.blue,
		Method = c.blue, Class = c.orange, Interface = c.green,
		Keyword = c.purple, Snippet = c.cyan, Text = c.comment,
		Struct = c.orange, TypeParameter = c.cyan, Enum = c.green,
		EnumMember = c.yellow, Property = c.fg, Constant = c.orange,
		Module = c.purple, Unit = c.orange, Value = c.fg,
		Reference = c.cyan, Color = c.green, File = c.blue,
		Folder = c.blue, Event = c.orange, Constr = c.orange,
	}
	for kind, color in pairs(kindHls) do
		hl("BlinkCmpKind" .. kind, { fg = color })
	end

	hl("BlinkCmpDoc", { link = "Normal" })
	hl("BlinkCmpSignatureHelp", { link = "Normal" })
	hl("BlinkCmpSignatureHelpActiveParameter", { fg = c.blue, bold = true })
	hl("BlinkCmpScrollBarThumb", { fg = c.border })
	hl("BlinkCmpScrollBarGutter", { fg = c.bgSubtle })

	hl("PmenuSel", { fg = c.fg, bg = c.selection, bold = true })
	hl("PmenuKind", { fg = c.comment })
	hl("PmenuKindSel", { fg = c.blue })
	hl("PmenuMatch", { fg = c.blue, bold = true })
	hl("PmenuMatchSel", { fg = c.blue, bold = true })
	hl("PmenuExtra", { fg = c.comment })

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

	hl("LspInlayHint", { fg = c.comment, bg = blend(c.fg, c.bg, 0.03), italic = true })
	hl("LspReferenceText", { bg = c.selection })
	hl("LspReferenceRead", { bg = c.selection })
	hl("LspReferenceWrite", { bg = c.selection })
	hl("LspCodeLens", { fg = c.comment })
	hl("LspCodeLensSeparator", { fg = c.comment })
	hl("LspSignatureActiveParameter", { fg = c.blue, bold = true })

	hl("@lsp.type.class", { fg = c.orange })
	hl("@lsp.type.function", { fg = c.blue })
	hl("@lsp.type.method", { fg = c.blue })
	hl("@lsp.type.parameter", { fg = c.fg, italic = true })
	hl("@lsp.type.variable", { fg = c.fg })
	hl("@lsp.type.property", { fg = c.fg })
	hl("@lsp.type.enumMember", { fg = c.yellow })
	hl("@lsp.type.keyword", { fg = c.purple })
	hl("@lsp.type.comment", { fg = c.comment, italic = true })

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

	hl("TabLineSel", { bg = c.bg, fg = c.fg, bold = true })
	hl("QuickFixLine", { bg = c.selection, bold = true })
	hl("ColorColumn", { bg = c.bgSubtle })
	hl("CmdlineCursor", { fg = c.bg, bg = c.blue })

	hl("SpellBad", { undercurl = true, sp = c.red })
	hl("SpellCap", { undercurl = true, sp = c.yellow })
	hl("SpellRare", { undercurl = true, sp = c.cyan })
	hl("SpellLocal", { undercurl = true, sp = c.blue })

	hl("Folded", { fg = c.comment, bg = c.bgSubtle })
	hl("FoldColumn", { fg = c.comment })

	vim.opt.foldtext = [[
		v:lua.require('theme').fold_text()
	]]
	function M.fold_text()
		local line = vim.fn.getline(vim.v.foldstart)
		local width = vim.fn.winwidth(0) - vim.fn.getwinvar(0, "&numberwidth") - 6
		local folded = vim.fn.printf(" %d lines ", vim.v.foldend - vim.v.foldstart + 1)
		local text = line:gsub("\t", string.rep(" ", vim.fn.shiftwidth()))
		if #text > width then
			text = text:sub(1, width) .. "…"
		end
		return text .. string.rep("─", math.max(width - #text - #folded, 1)) .. folded
	end

	hl("TreesitterContextSeparator", { fg = c.border })
	hl("TreesitterContextBottom", { link = "TreesitterContext" })

	hl("CopilotSuggestion", { fg = c.purple, italic = true })
	hl("CopilotPanelLabel", { fg = c.blue, bold = true })
	hl("CopilotPanelSelected", { fg = c.blue, bg = c.selection, bold = true })

	hl("MiniHipatternsFixme", { fg = c.bg, bg = c.red, bold = true })
	hl("MiniHipatternsTodo", { fg = c.bg, bg = c.orange, bold = true })
	hl("MiniHipatternsNote", { fg = c.bg, bg = c.blue, bold = true })
	hl("MiniHipatternsHack", { fg = c.bg, bg = c.purple, bold = true })
	hl("MiniIndentscopeSymbol", { fg = indent })
	hl("MiniCursorword", { bg = c.selection })
	hl("MiniCursorwordCurrent", { bg = c.selection })
	hl("MiniPickNormal", { link = "Normal" })
	hl("MiniPickBorder", { link = "GlobalBorder" })
	hl("MiniPickMatchCurrent", { fg = c.blue, bold = true })
	hl("MiniPickMatchMarked", { fg = c.blue, bold = true })
	hl("MiniPickPreviewLine", { fg = c.comment })

	hl("OilDir", { fg = c.blue, bold = true })
	hl("OilDirIcon", { fg = c.blue })
	hl("OilFile", { link = "Normal" })

	hl("NeogitBranch", { fg = c.blue, bold = true })
	hl("NeogitRemote", { fg = c.yellow })
	hl("NeogitHunkHeader", { fg = c.blue, bg = c.bgSubtle })
	hl("NeogitHunkHeaderHighlight", { fg = c.blue, bg = c.selection })
	hl("NeogitDiffAdd", { fg = c.green, bg = blend(c.green, c.bg, 0.10) })
	hl("NeogitDiffDelete", { fg = c.red, bg = blend(c.red, c.bg, 0.10) })
	hl("NeogitDiffAddHighlight", { fg = c.green, bg = blend(c.green, c.bg, 0.18) })
	hl("NeogitDiffDeleteHighlight", { fg = c.red, bg = blend(c.red, c.bg, 0.18) })
	hl("NeogitDiffContextHighlight", { bg = c.bgSubtle })
	hl("NeogitDiffHeader", { fg = c.blue })
	hl("NeogitSectionHeader", { fg = c.blue, bold = true })
	hl("NeogitFilePath", { fg = c.blue, italic = true })
	hl("NeogitGraphRed", { fg = c.red })
	hl("NeogitGraphGreen", { fg = c.green })
	hl("NeogitGraphBlue", { fg = c.blue })
	hl("NeogitGraphPurple", { fg = c.purple })
	hl("NeogitGraphYellow", { fg = c.yellow })
	hl("NeogitGraphCyan", { fg = c.cyan })
	hl("NeogitGraphGray", { fg = c.comment })
	hl("NeogitGraphWhite", { fg = c.fg })
	hl("NeogitNotificationInfo", { fg = c.blue })
	hl("NeogitNotificationWarning", { fg = c.yellow })
	hl("NeogitNotificationError", { fg = c.red })
	hl("NeogitCommitViewHeader", { fg = c.blue, bold = true })

	hl("StlMode", { fg = c.bg, bg = c.blue, bold = true })
	hl("StlGit", { fg = c.comment })
	hl("StlDiag", { fg = c.comment })
	hl("StlFile", { fg = c.fg })
	hl("StlLSP", { fg = c.comment })
	hl("StlFT", { fg = c.comment })
	hl("StlPos", { fg = c.comment })
end

return M
