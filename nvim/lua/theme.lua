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
	magenta = generated.magenta or "#c48282",
	selection = generated.selection or "#333738",
	search = generated.search or "#2a3a4a",
	trailspace = generated.trailspace or "#3a1c28",
}

function M.setup()
	local c = M.colors
	if generated.variant == "light" then
		vim.o.background = "light"
	elseif generated.variant == "dark" then
		vim.o.background = "dark"
	end
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

	local hl = function(name, opts)
		vim.api.nvim_set_hl(0, name, opts)
	end

	-- Force a flat UI background: all UI/popup surfaces match editor background.
	hl("Normal", { fg = c.fg, bg = c.bg })
	for _, group in ipairs({
		"NormalNC",
		"NormalFloat",
		"SignColumn",
		"FoldColumn",
		"StatusLine",
		"StatusLineNC",
		"WinBar",
		"WinBarNC",
		"Pmenu",
		"PmenuSbar",
		"PmenuThumb",
		"BlinkCmpMenu",
		"BlinkCmpDoc",
		"BlinkCmpSignatureHelp",
		"NoiceCmdlinePopup",
		"NoiceConfirm",
		"NoicePopup",
		"NoicePopupmenu",
		"FzfLuaNormal",
		"FzfLuaPreviewNormal",
		"FzfLuaPromptNormal",
		"MiniClueNormal",
		"TreesitterContext",
	}) do
		hl(group, { link = "Normal" })
	end
	hl("CursorLine", { bg = c.bg })
	hl("PmenuSel", { fg = c.blue, bg = c.bg, bold = true })
	hl("BlinkCmpMenuSelection", { fg = c.blue, bg = c.bg, bold = true })

	-- Keep overrides minimal so mini.base16/Stylix drives most colors.
	hl("GlobalBorder", { fg = c.border })
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
	hl("WinSeparator", { fg = c.border })

	-- Accent-only tweaks (avoid background overrides).
	hl("FloatTitle", { fg = c.blue, bold = true })
	hl("LspInfoTitle", { fg = c.blue, bold = true })
	hl("NoiceCmdlinePopupTitle", { fg = c.blue, bold = true })
	hl("NoicePopupmenuMatch", { fg = c.blue, bold = true })
	hl("MiniClueTitle", { fg = c.blue, bold = true })
	hl("MiniClueDescGroup", { fg = c.comment })
	hl("MiniClueNextKey", { fg = c.blue, bold = true })
	hl("MiniClueNextKeyWithPostkeys", { fg = c.blue, bold = true })
	hl("MiniClueSeparator", { fg = c.border })
	hl("BlinkCmpLabelMatch", { fg = c.blue, bold = true })

	-- Diagnostics and subtle utility highlights.
	hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
	hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
	hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.cyan })
	hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.blue })
	hl("LspInlayHint", { fg = c.comment, italic = true })
	hl("MiniIndentscopeSymbol", { fg = c.comment, nocombine = true })
	hl("MiniTrailspace", { bg = c.trailspace })
	hl("CopilotSuggestion", { fg = c.purple, italic = true })
end

return M
