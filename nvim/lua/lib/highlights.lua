local M = {}

function M.apply()
	local hl = vim.api.nvim_set_hl

	hl(0, "NormalFloat", { bg = "none" })
	hl(0, "FloatBorder", { fg = "#7e9cd8", bg = "none" })
	hl(0, "CursorLine", { bg = "#2a2a37" })
	hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#e82424" })
	hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "#ff9e3b" })

	hl(0, "BlinkCmpKindSnippet", { fg = "#f38ba8" })
	hl(0, "BlinkCmpKindKeyword", { fg = "#cba6f7" })
	hl(0, "BlinkCmpKindText", { fg = "#a6e3a1" })

	hl(0, "DiagnosticLineError", { bg = "#2a1720" })
	hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
	hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
	hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

	hl(0, "CopilotSuggestion", { fg = "#708090", bg = "#1a1f2e", italic = true, blend = 80 })

	hl(0, "NeogitPopupBorder", { bg = "none", fg = "#4a4a5a" })
	hl(0, "NeogitFloatBorder", { bg = "none", fg = "#4a4a5a" })
	hl(0, "NeogitSectionHeader", { fg = "#6e94b2", bold = true })
	hl(0, "NeogitUnstagedChanges", { fg = "#d8647e" })
	hl(0, "NeogitStagedChanges", { fg = "#7fa563" })

	hl(0, "MiniTrailspace", { bg = "#3a1c28" })
end

return M
