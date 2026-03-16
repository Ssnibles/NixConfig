-- lua/lib/highlights.lua
-- Centralized highlight group overrides for single-surface aesthetic
local M = {}

function M.apply()
	local hl = vim.api.nvim_set_hl
	local nor = vim.api.nvim_get_hl(0, { name = "Normal" })
	local bdr = "#4a4a5a"

	-- Float surfaces
	hl(0, "FloatBorder", { bg = nor.bg, fg = bdr })
	hl(0, "NormalFloat", { bg = nor.bg, fg = nor.fg })
	hl(0, "FzfLuaBorder", { bg = nor.bg, fg = bdr })
	hl(0, "FzfLuaNormal", { bg = nor.bg, fg = nor.fg })

	-- Diagnostic line backgrounds
	hl(0, "DiagnosticLineError", { bg = "#2a1720" })
	hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
	hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
	hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

	-- Indent guides
	hl(0, "IblIndent", { fg = "#2a2a30" })
	hl(0, "IblScope", { fg = "#404050" })
	hl(0, "IblScopeUnderline", { sp = "#4a4a6a", underline = true })

	-- Noice
	hl(0, "NoiceCmdline", { bg = nor.bg, fg = bdr })
	hl(0, "NoiceCmdlinePopup", { bg = nor.bg })
	hl(0, "NoiceCmdlinePopupBorder", { bg = nor.bg, fg = bdr })

	-- blink.cmp menus
	hl(0, "BlinkMenuNormal", { bg = nor.bg, fg = nor.fg })
	hl(0, "BlinkCmpMenu", { bg = nor.bg, fg = bdr })
	hl(0, "BlinkCmpMenuBorder", { bg = nor.bg, fg = bdr })
	hl(0, "BlinkMenuBorder", { bg = nor.bg, fg = bdr })
	hl(0, "BlinkMenuSel", { bg = "#2a2a30", fg = nor.fg })

	-- blink.cmp docs
	hl(0, "BlinkCmpDoc", { bg = nor.bg, fg = bdr })
	hl(0, "BlinkCmpDocBorder", { bg = nor.bg, fg = bdr })
	hl(0, "BlinkCmpDocSeparator", { bg = nor.bg, fg = bdr })
	hl(0, "BlinkCmpSignatureHelp", { bg = nor.bg, fg = bdr })
	hl(0, "BlinkCmpSignatureHelpBorder", { bg = nor.bg, fg = bdr })

	-- blink.cmp kind icons (preserved from original)
	hl(0, "BlinkCmpKindFunction", { fg = "#c48282" })
	hl(0, "BlinkCmpKindMethod", { fg = "#c48282" })
	hl(0, "BlinkCmpKindKeyword", { fg = "#6e94b2" })
	hl(0, "BlinkCmpKindVariable", { fg = nor.fg })
	hl(0, "BlinkCmpKindConstant", { fg = "#bb9dbd" })
	hl(0, "BlinkCmpKindClass", { fg = "#9bb4bc" })
	hl(0, "BlinkCmpKindInterface", { fg = "#9bb4bc" })
	hl(0, "BlinkCmpKindStruct", { fg = "#9bb4bc" })
	hl(0, "BlinkCmpKindModule", { fg = "#b4d4cf" })
	hl(0, "BlinkCmpKindField", { fg = "#bb9dbd" })
	hl(0, "BlinkCmpKindProperty", { fg = "#bb9dbd" })
	hl(0, "BlinkCmpKindEnum", { fg = "#f3be7c" })
	hl(0, "BlinkCmpKindEnumMember", { fg = "#f3be7c" })
	hl(0, "BlinkCmpKindSnippet", { fg = "#606079" })
	hl(0, "BlinkCmpKindText", { fg = "#606079" })

	-- Misc
	-- hl(0, "NonText", { fg = "#2a2a30" })
	hl(0, "MiniTrailspace", { bg = "#3a1c28" })
end

return M
