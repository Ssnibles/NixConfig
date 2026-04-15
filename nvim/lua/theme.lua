-- Theme configuration from Stylix-generated palette + custom highlight overrides
local M = {}

local ok, generated = pcall(require, "generated.colors")
if not ok then
	generated = {}
end

M.colors = {
	bg = generated.bg or "#141415",
	fg = generated.fg or "#cdcdcd",
	comment = generated.fg_dim or "#606079",
	gutter = generated.bg_subtle or "#252530",
	border = generated.border or "#252530",
	blue = generated.accent or "#6e94b2",
	purple = generated.purple or "#bb9dbd",
	green = generated.green or "#7fa563",
	red = generated.red or "#d8647e",
	yellow = generated.yellow or "#f3be7c",
	cyan = generated.teal or "#b4d4cf",
	orange = generated.orange or "#e8b589",
	selection = generated.selection or "#333738",
	search = generated.search or "#2a3a4a",
	trailspace = generated.trailspace or "#3a1c28",
}

function M.setup()
	local c = M.colors
	local ok_base16, mini_base16 = pcall(require, "mini.base16")
	if ok_base16 then
		mini_base16.setup({
			palette = {
				base00 = generated.base00 or c.bg,
				base01 = generated.base01 or c.search,
				base02 = generated.base02 or c.selection,
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
	hl("NormalFloat", { fg = c.fg, bg = c.bg })
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
	hl("Visual", { bg = c.selection })
	hl("LineNr", { fg = c.comment })

	-- Search
	hl("Search", { bg = c.search, fg = c.blue })
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
	hl("MiniIndentscopeSymbol", { fg = c.blue, nocombine = true })

	-- Mini.nvim
	hl("MiniCursorword", { bg = c.gutter })
	hl("MiniCursorwordCurrent", { bg = c.gutter })
	hl("MiniTrailspace", { bg = c.trailspace })

	-- Folds
	hl("Folded", { fg = c.comment, bg = c.gutter })
	hl("FoldColumn", { fg = c.comment })

	-- Copilot
	hl("CopilotSuggestion", { fg = c.purple, italic = true })
end

return M
