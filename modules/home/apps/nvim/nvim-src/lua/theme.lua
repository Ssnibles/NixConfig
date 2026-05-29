-- Theme: Stylix-generated palette + comprehensive Zed-inspired highlight overrides
-- Philosophy: flat, unified surfaces; ultra-subtle separators; accent-only typography.
-- Every UI panel shares the editor background. Borders are nearly invisible.

local M = {}

local ok, generated = pcall(require, "generated.colors")
if not ok then
	generated = {}
end

M.colors = {
	bg = generated.bg or "#141415",
	fg = generated.fg or "#cdcdcd",
	comment = generated.fg_dim or "#606079",
	bgSubtle = generated.bg_subtle or "#252530",
	gutter = generated.bg_subtle or "#252530",
	border = generated.border or "#252530",
	blue = generated.accent or "#6e94b2",
	purple = generated.purple or "#bb9dbd",
	green = generated.green or "#7fa563",
	red = generated.red or "#d8647e",
	yellow = generated.yellow or "#f3be7c",
	cyan = generated.teal or "#b4d4cf",
	orange = generated.orange or "#e8b589",
	magenta = generated.magenta or "#c48282",
	selection = generated.selection or "#333738",
	search = generated.search or "#2a3a4a",
	trailspace = generated.trailspace or "#3a1c28",
}

--- Blend two hex colours with an alpha factor (0 = pure bg, 1 = pure fg).
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

	-- Set background variant from Stylix metadata.
	if generated.variant == "light" then
		vim.o.background = "light"
	elseif generated.variant == "dark" then
		vim.o.background = "dark"
	end

	-- Mini.base16 drives the core syntax palette.
	local ok_base16, mini_base16 = pcall(require, "mini.base16")
	if ok_base16 then
		mini_base16.setup({
			palette = {
				base00 = generated.base00 or c.bg,
				base01 = generated.base00 or c.bg,
				base02 = generated.base00 or c.bg,
				base03 = generated.base03 or c.comment,
				base04 = generated.base04 or c.comment,
				base05 = generated.base05 or c.fg,
				base06 = generated.base06 or c.fg,
				base07 = generated.base07 or c.fg,
				base08 = generated.base08 or c.red,
				base09 = generated.base09 or c.orange,
				base0A = generated.base0A or c.yellow,
				base0B = generated.base0B or c.green,
				base0C = generated.base0C or c.cyan,
				base0D = generated.base0D or c.blue,
				base0E = generated.base0E or c.purple,
				base0F = generated.base0F or c.magenta,
			},
		})
	end

	-- Derived colours
	local separator = blend(c.fg, c.bg, 0.06)
	local indent = blend(c.comment, c.bg, 0.35)
	local indentScope = blend(c.blue, c.bg, 0.40)

	local hl = function(name, opts)
		vim.api.nvim_set_hl(0, name, opts)
	end

	-- ═══════════════════════════════════════════════════════════════
	-- FLAT UI BACKDROPS
	-- Every panel, float, popup, and menu shares the editor background
	-- for a seamless, unified look.
	-- ═══════════════════════════════════════════════════════════════
	hl("Normal", { fg = c.fg, bg = c.bg })

	for _, group in ipairs({
		-- Editor chrome
		"NormalNC",
		"NormalFloat",
		"SignColumn",
		"FoldColumn",
		"StatusLine",
		"StatusLineNC",
		"WinBar",
		"WinBarNC",
		"MsgArea",
		"MsgSeparator",
		-- Completion / menu surfaces
		"Pmenu",
		"PmenuSbar",
		"PmenuThumb",
		"BlinkCmpMenu",
		"BlinkCmpDoc",
		"BlinkCmpSignatureHelp",
		"BlinkCmpGhostText",
		-- Noice
		"NoiceCmdlinePopup",
		"NoiceConfirm",
		"NoicePopup",
		"NoicePopupmenu",
		"NoiceFormatConfirm",
		"NoiceFormatProgress",
		"NoiceFormatTitle",
		-- FzfLua
		"FzfLuaNormal",
		"FzfLuaPreviewNormal",
		"FzfLuaPromptNormal",
		"FzfLuaCursor",
		"FzfLuaHelpNormal",
		"FzfLuaHelpBorder",
		-- Mini
		"MiniClueNormal",
		"MiniAnimateNormalFloat",
		"MiniDepsChangeAdded",
		"MiniDepsChangeRemoved",
		-- Treesitter context
		"TreesitterContext",
		"TreesitterContextLineNumber",
		-- Dashboard (alpha)
		"AlphaNormal",
		"AlphaHeader",
		"AlphaButtons",
		"AlphaShortcut",
		"AlphaFooter",
		-- DAP UI
		"DAPUINormal",
		"DAPUIFloatNormal",
		-- TabLine
		"TabLine",
		"TabLineFill",
		-- Oil
		"OilNormal",
		-- Snacks
		"SnacksIndent",
		"SnacksIndentScope",
		"SnacksIndentChunk",
	}) do
		hl(group, { link = "Normal" })
	end

	-- ═══════════════════════════════════════════════════════════════
	-- TYPOGRAPHY & EDITOR TEXT
	-- ═══════════════════════════════════════════════════════════════
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

	-- Whitespace & conceal: near-invisible
	hl("NonText", { fg = blend(c.comment, c.bg, 0.3) })
	hl("Whitespace", { fg = blend(c.comment, c.bg, 0.15) })
	hl("Conceal", { fg = c.comment })
	hl("EndOfBuffer", { fg = c.bg })

	-- ═══════════════════════════════════════════════════════════════
	-- GUTTER & STATUS COLUMN
	-- ═══════════════════════════════════════════════════════════════
	hl("LineNr", { fg = c.comment, bg = c.bg })
	hl("LineNrAbove", { fg = c.comment })
	hl("LineNrBelow", { fg = c.comment })

	-- ═══════════════════════════════════════════════════════════════
	-- SPLITS & WINDOW SEPARATORS (near-invisible)
	-- ═══════════════════════════════════════════════════════════════
	hl("WinSeparator", { fg = separator })

	-- ═══════════════════════════════════════════════════════════════
	-- BORDERS
	-- ═══════════════════════════════════════════════════════════════
	hl("GlobalBorder", { fg = c.border })
	hl("FloatBorder", { link = "GlobalBorder" })
	hl("FloatTitle", { fg = c.blue, bold = true })
	hl("FloatFooter", { fg = c.comment })

	hl("LspInfoBorder", { link = "GlobalBorder" })
	hl("LspInfoTitle", { fg = c.blue, bold = true })

	-- FzfLua
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

	-- Noice
	hl("NoiceCmdlinePopupBorder", { link = "GlobalBorder" })
	hl("NoiceConfirmBorder", { link = "GlobalBorder" })
	hl("NoicePopupBorder", { link = "GlobalBorder" })
	hl("NoicePopupmenuBorder", { link = "GlobalBorder" })
	hl("NoiceFormatConfirmBorder", { link = "GlobalBorder" })
	hl("NoiceCmdlinePopupTitle", { fg = c.blue, bold = true })
	hl("NoicePopupmenuMatch", { fg = c.blue, bold = true })

	-- Mini.clue
	hl("MiniClueBorder", { link = "GlobalBorder" })
	hl("MiniClueTitle", { fg = c.blue, bold = true })
	hl("MiniClueDescGroup", { fg = c.comment })
	hl("MiniClueNextKey", { fg = c.blue, bold = true })
	hl("MiniClueNextKeyWithPostkeys", { fg = c.blue, bold = true })
	hl("MiniClueSeparator", { fg = c.border })

	-- Blink.cmp
	hl("BlinkCmpMenuBorder", { link = "GlobalBorder" })
	hl("BlinkCmpDocBorder", { link = "GlobalBorder" })
	hl("BlinkCmpSignatureHelpBorder", { link = "GlobalBorder" })

	-- Snacks borders
	hl("SnacksTerminalBorder", { link = "GlobalBorder" })
	hl("SnacksTerminalNormal", { link = "Normal" })
	hl("SnacksIndentScope", { fg = indentScope, nocombine = true })

	-- Alpha dashboard tinting
	hl("AlphaHeader", { fg = c.blue, bold = true })
	hl("AlphaHeaderLabel", { fg = c.comment })
	hl("AlphaShortcut", { fg = c.orange })
	hl("AlphaButtons", { link = "Normal" })
	hl("AlphaFooter", { fg = c.comment, italic = true })

	-- ═══════════════════════════════════════════════════════════════
	-- BLINK.CMP DETAILS
	-- ═══════════════════════════════════════════════════════════════
	hl("BlinkCmpMenuSelection", { fg = c.fg, bg = c.selection, bold = true })
	hl("BlinkCmpLabelMatch", { fg = c.blue, bold = true })
	hl("BlinkCmpLabelDetail", { fg = c.comment, italic = true })
	hl("BlinkCmpLabelDescription", { fg = c.comment })
	hl("BlinkCmpSource", { fg = c.comment })
	hl("BlinkCmpKind", { fg = c.comment })

	local kindHls = {
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
		Operator = c.cyan,
		Color = c.green,
		File = c.blue,
		Folder = c.blue,
		Event = c.orange,
		Constr = c.orange,
	}
	for kind, color in pairs(kindHls) do
		hl("BlinkCmpKind" .. kind, { fg = color })
	end

	hl("BlinkCmpDoc", { link = "Normal" })
	hl("BlinkCmpSignatureHelp", { link = "Normal" })
	hl("BlinkCmpSignatureHelpActiveParameter", { fg = c.blue, bold = true })
	hl("BlinkCmpScrollBarThumb", { fg = c.border })
	hl("BlinkCmpScrollBarGutter", { fg = c.bgSubtle })

	-- Pmenu (cmdline / fallback)
	hl("PmenuSel", { fg = c.fg, bg = c.selection, bold = true })
	hl("PmenuKind", { fg = c.comment })
	hl("PmenuKindSel", { fg = c.blue })
	hl("PmenuMatch", { fg = c.blue, bold = true })
	hl("PmenuMatchSel", { fg = c.blue, bold = true })
	hl("PmenuExtra", { fg = c.comment })

	-- ═══════════════════════════════════════════════════════════════
	-- DIAGNOSTICS
	-- ═══════════════════════════════════════════════════════════════
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

	-- Virtual diagnostic text -- tinted backgrounds with a coloured bar prefix
	hl("DiagnosticVirtualTextError", { fg = c.red, bg = blend(c.red, c.bg, 0.10) })
	hl("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = blend(c.yellow, c.bg, 0.10) })
	hl("DiagnosticVirtualTextHint", { fg = c.cyan, bg = blend(c.cyan, c.bg, 0.08) })
	hl("DiagnosticVirtualTextInfo", { fg = c.blue, bg = blend(c.blue, c.bg, 0.08) })

	hl("DiagnosticDeprecated", { strikethrough = true, sp = c.comment })

	hl("DiagnosticFloatingError", { fg = c.red })
	hl("DiagnosticFloatingWarn", { fg = c.yellow })
	hl("DiagnosticFloatingHint", { fg = c.cyan })
	hl("DiagnosticFloatingInfo", { fg = c.blue })

	-- ═══════════════════════════════════════════════════════════════
	-- LSP
	-- ═══════════════════════════════════════════════════════════════
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

	-- ═══════════════════════════════════════════════════════════════
	-- GIT (Gitsigns / Diff)
	-- ═══════════════════════════════════════════════════════════════
	hl("DiffAdd", { bg = blend(c.green, c.bg, 0.12) })
	hl("DiffDelete", { bg = blend(c.red, c.bg, 0.12) })
	hl("DiffChange", { bg = blend(c.yellow, c.bg, 0.12) })
	hl("DiffText", { bg = blend(c.blue, c.bg, 0.2) })

	hl("DiffAddGutter", { fg = c.green, bg = c.bg })
	hl("DiffDeleteGutter", { fg = c.red, bg = c.bg })
	hl("DiffChangeGutter", { fg = c.yellow, bg = c.bg })

	-- Gitsigns sign column symbols
	hl("GitSignsAdd", { fg = c.green })
	hl("GitSignsChange", { fg = c.yellow })
	hl("GitSignsDelete", { fg = c.red })
	hl("GitSignsCurrentLineBlame", { fg = c.comment, italic = true })

	-- ═══════════════════════════════════════════════════════════════
	-- OTHER UI
	-- ═══════════════════════════════════════════════════════════════
	hl("TabLineSel", { bg = c.bg, fg = c.fg, bold = true })
	hl("QuickFixLine", { bg = c.selection, bold = true })
	hl("ColorColumn", { bg = c.bgSubtle })

	hl("SpellBad", { undercurl = true, sp = c.red })
	hl("SpellCap", { undercurl = true, sp = c.yellow })
	hl("SpellRare", { undercurl = true, sp = c.cyan })
	hl("SpellLocal", { undercurl = true, sp = c.blue })

	hl("Folded", { fg = c.comment, bg = c.bgSubtle })
	hl("FoldColumn", { fg = c.comment })

	-- Treesitter context: bottom separator line blends into background
	hl("TreesitterContextSeparator", { fg = c.border })
	hl("TreesitterContextBottom", { link = "TreesitterContext" })

	-- ═══════════════════════════════════════════════════════════════
	-- COPILOT
	-- ═══════════════════════════════════════════════════════════════
	hl("CopilotSuggestion", { fg = c.purple, italic = true })
	hl("CopilotPanelLabel", { fg = c.blue, bold = true })
	hl("CopilotPanelSelected", { fg = c.blue, bg = c.selection, bold = true })

	-- ═══════════════════════════════════════════════════════════════
	-- MINI.NVIM SUB-HIGHLIGHTS
	-- ═══════════════════════════════════════════════════════════════
	hl("MiniHipatternsFixme", { fg = c.bg, bg = c.red, bold = true })
	hl("MiniHipatternsTodo", { fg = c.bg, bg = c.orange, bold = true })
	hl("MiniHipatternsNote", { fg = c.bg, bg = c.blue, bold = true })
	hl("MiniHipatternsHack", { fg = c.bg, bg = c.purple, bold = true })
	hl("MiniIndentscopeSymbol", { fg = indent })
	hl("MiniTrailspace", { bg = c.trailspace })
	hl("MiniCursorword", { bg = c.selection })
	hl("MiniCursorwordCurrent", { bg = c.selection })
	hl("MiniPickNormal", { link = "Normal" })
	hl("MiniPickBorder", { link = "GlobalBorder" })
	hl("MiniPickMatchCurrent", { fg = c.blue, bold = true })
	hl("MiniPickMatchMarked", { fg = c.blue, bold = true })
	hl("MiniPickPreviewLine", { fg = c.comment })

	-- ═══════════════════════════════════════════════════════════════
	-- OIL (file-tree style)
	-- ═══════════════════════════════════════════════════════════════
	hl("OilDir", { fg = c.blue, bold = true })
	hl("OilDirIcon", { fg = c.blue })
	hl("OilFile", { link = "Normal" })

	-- ═══════════════════════════════════════════════════════════════
	-- NEOGIT
	-- ═══════════════════════════════════════════════════════════════
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

	-- ═══════════════════════════════════════════════════════════════
	-- LUALINE THEME CONTRACT
	-- ═══════════════════════════════════════════════════════════════
	M.lualine = {
		normal = {
			a = { fg = c.bg, bg = c.blue, gui = "bold" },
			b = { fg = c.fg, bg = c.bg },
			c = { fg = c.comment, bg = c.bg },
		},
		insert = { a = { fg = c.bg, bg = c.green, gui = "bold" } },
		visual = { a = { fg = c.bg, bg = c.purple, gui = "bold" } },
		replace = { a = { fg = c.bg, bg = c.red, gui = "bold" } },
		command = { a = { fg = c.bg, bg = c.cyan, gui = "bold" } },
		terminal = { a = { fg = c.bg, bg = c.orange, gui = "bold" } },
		inactive = { a = { fg = c.comment, bg = c.bg } },
	}

	-- ═══════════════════════════════════════════════════════════════
	-- STATUSCOL CONTRACT
	-- ═══════════════════════════════════════════════════════════════
	M.statuscol = {
		fold = c.comment,
		gutter = c.comment,
		number = c.comment,
		current = c.blue,
	}
end

return M
