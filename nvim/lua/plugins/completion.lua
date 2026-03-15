-- blink.cmp — async completion engine.
-- Exposes capabilities() so lsp.lua can call it without coupling.

require("blink.cmp").setup({
	keymap = { preset = "super-tab" },

	cmdline = {
		keymap = {
			["<Tab>"] = { "accept", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
		},
		completion = {
			menu = { auto_show = true },
			ghost_text = { enabled = true },
		},
	},

	completion = {
		menu = {
			auto_show = true,
			border = "rounded",
			winhighlight = "Normal:BlinkMenuNormal,FloatBorder:BlinkMenuBorder,CursorLine:BlinkMenuSel,Search:None",
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 100,
			window = {
				border = "rounded",
				winhighlight = "Normal:BlinkMenuNormal,FloatBorder:BlinkMenuBorder",
			},
		},
		ghost_text = { enabled = true },
	},

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
})

-- Load VS Code-format snippets from friendly-snippets.
require("luasnip.loaders.from_vscode").lazy_load()

-- ── Highlight overrides ───────────────────────────────────────────────────
-- Set after colorscheme so vague doesn't reset them.
-- Must run before blink.setup() references these groups — but since Lua files
-- are executed top-to-bottom and this is all in one file, order is fine.

local hl = vim.api.nvim_set_hl
local nor = vim.api.nvim_get_hl(0, { name = "Normal" })
local bdr = "#565f89" -- border: slightly brighter than fg-mid

-- Float surfaces
hl(0, "FloatBorder", { bg = nor.bg, fg = bdr })
hl(0, "NormalFloat", { bg = nor.bg, fg = nor.fg })
hl(0, "FzfLuaBorder", { bg = nor.bg, fg = bdr })
hl(0, "FzfLuaNormal", { bg = nor.bg, fg = nor.fg })

-- Diagnostic line backgrounds (blended tints against #141415)
hl(0, "DiagnosticLineError", { bg = "#2a1720" })
hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

-- Indent-blankline
hl(0, "IblIndent", { fg = "#252530" })
hl(0, "IblScope", { fg = "#6e94b2" })

-- Noice
hl(0, "NoiceCmdline", { bg = nor.bg, fg = bdr })
hl(0, "NoiceCmdlinePopup", { bg = nor.bg })
hl(0, "NoiceCmdlinePopupBorder", { bg = nor.bg, fg = bdr })

-- blink.cmp menu surfaces
hl(0, "BlinkMenuNormal", { bg = nor.bg, fg = nor.fg })
hl(0, "BlinkCmpMenu", { bg = nor.bg, fg = bdr })
hl(0, "BlinkCmpMenuBorder", { bg = nor.bg, fg = bdr })
hl(0, "BlinkMenuBorder", { bg = nor.bg, fg = bdr })
hl(0, "BlinkMenuSel", { bg = "#252530", fg = nor.fg })

-- blink.cmp docs
hl(0, "BlinkCmpDoc", { bg = nor.bg, fg = bdr })
hl(0, "BlinkCmpDocBorder", { bg = nor.bg, fg = bdr })
hl(0, "BlinkCmpDocSeparator", { bg = nor.bg, fg = bdr })
hl(0, "BlinkCmpSignatureHelp", { bg = nor.bg, fg = bdr })
hl(0, "BlinkCmpSignatureHelpBorder", { bg = nor.bg, fg = bdr })

-- blink.cmp kind icons — mapped to vague semantic colours
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

-- Hide NonText chars (listchars) — blend them into the background
hl(0, "NonText", { fg = nor.bg })
