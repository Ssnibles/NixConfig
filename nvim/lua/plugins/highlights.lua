-- ============================================================================
-- HIGHLIGHT OVERRIDES
-- Custom highlight groups set after the colorscheme loads so vague doesn't
-- reset them. All colour values are taken directly from the vague.nvim
-- palette — the same palette used in Waybar, Hyprland, fish, and vicinae —
-- so every surface in the system shares one colour language.
--
-- vague palette reference (mirrors the @define-color block in waybar.nix):
--   bg          #141415  — main background
--   bg-raised   #1c1c24  — inactiveBg / raised surface
--   border      #252530  — line / 1px dividers
--   fg          #cdcdcd  — primary text
--   fg-dim      #606079  — comment / dimmed text
--   fg-mid      #878787  — floatBorder / mid-tone
--   keyword     #6e94b2  — blue accent
--   builtin     #b4d4cf  — teal
--   parameter   #bb9dbd  — muted purple
--   warning     #f3be7c  — amber
--   error       #d8647e  — red
--   plus        #7fa563  — green
-- ============================================================================

local set_hl = vim.api.nvim_set_hl
local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
local border_fg = "#565f89"

-- ============================================================================
-- DIAGNOSTIC LINE BACKGROUNDS
-- Used by the line_hl_group extmark in autocommands.lua to tint the entire
-- line behind diagnostics. We can't use the built-in DiagnosticVirtualText*
-- groups here because vague defines those with a near-invisible background
-- tint intended only for virtual text padding — not a full line wash.
--
-- These groups use the vague semantic fg colour at low opacity blended
-- against the bg, giving a clearly visible but non-garish line tint:
--   error   → #d8647e tinted  →  #2a1720  (dark red wash)
--   warn    → #f3be7c tinted  →  #271f10  (dark amber wash)
--   info    → #6e94b2 tinted  →  #131c27  (dark blue wash)
--   hint    → #b4d4cf tinted  →  #141e1d  (dark teal wash)
-- ============================================================================
set_hl(0, "DiagnosticLineError", { bg = "#2a1720" })
set_hl(0, "DiagnosticLineWarn", { bg = "#271f10" })
set_hl(0, "DiagnosticLineInfo", { bg = "#131c27" })
set_hl(0, "DiagnosticLineHint", { bg = "#141e1d" })

-- ============================================================================
-- FLOAT BORDERS
-- All floating window borders use the same muted tone as the Blink.cmp
-- borders, keeping every popup surface visually consistent.
-- ============================================================================
set_hl(0, "FloatBorder", { bg = normal.bg, fg = border_fg })
set_hl(0, "NormalFloat", { bg = normal.bg, fg = normal.fg })
set_hl(0, "FzfLuaBorder", { bg = normal.bg, fg = border_fg })
set_hl(0, "FzfLuaNormal", { bg = normal.bg, fg = normal.fg })

-- ============================================================================
-- INDENT-BLANKLINE
-- IblIndent uses the line colour (#252530) — the same value as Waybar's
-- 1px solid border — so the guides are barely visible, just like the thin
-- dividers between Waybar modules.
-- IblScope uses keyword blue to mark the active block.
-- ============================================================================
set_hl(0, "IblIndent", { fg = "#252530" }) -- line / border colour
set_hl(0, "IblScope", { fg = "#6e94b2" }) -- keyword blue

-- ============================================================================
-- BLINK.CMP
-- The completion menu is styled to match the normal buffer surface so it
-- doesn't feel like a foreign overlay — bg and fg are pulled directly from
-- the Normal highlight group, and borders use the same muted tone used
-- throughout the rest of the UI.
-- ============================================================================

-- Menu surface — matches Normal bg/fg
set_hl(0, "BlinkMenuNormal", { bg = normal.bg, fg = normal.fg })
set_hl(0, "BlinkCmpMenu", { bg = normal.bg, fg = border_fg })
set_hl(0, "BlinkCmpMenuBorder", { bg = normal.bg, fg = border_fg })

-- Border — muted, consistent with FloatBorder across the rest of the UI
set_hl(0, "BlinkMenuBorder", { bg = normal.bg, fg = border_fg })

-- Selected item — one step lighter than the surface
set_hl(0, "BlinkMenuSel", { bg = "#252530", fg = normal.fg })

-- Documentation popup
set_hl(0, "BlinkCmpDoc", { bg = normal.bg, fg = border_fg })
set_hl(0, "BlinkCmpDocBorder", { bg = normal.bg, fg = border_fg })
set_hl(0, "BlinkCmpDocSeparator", { bg = normal.bg, fg = border_fg })

-- Signature help
set_hl(0, "BlinkCmpSignatureHelp", { bg = normal.bg, fg = border_fg })
set_hl(0, "BlinkCmpSignatureHelpBorder", { bg = normal.bg, fg = border_fg })

-- ============================================================================
-- NOICE
-- ============================================================================
set_hl(0, "NoiceCmdline", { bg = normal.bg, fg = border_fg })
set_hl(0, "NoiceCmdlinePopup", { bg = normal.bg })
set_hl(0, "NoiceCmdlinePopupBorder", { bg = normal.bg, fg = border_fg })

-- ============================================================================
-- BLINK.CMP — kind icon colours
-- Map LSP completion kinds to vague semantic colours, consistent with how
-- treesitter highlights the same constructs in the buffer.
-- ============================================================================
set_hl(0, "BlinkCmpKindFunction", { fg = "#c48282" }) -- func
set_hl(0, "BlinkCmpKindMethod", { fg = "#c48282" }) -- func
set_hl(0, "BlinkCmpKindKeyword", { fg = "#6e94b2" }) -- keyword
set_hl(0, "BlinkCmpKindVariable", { fg = normal.fg }) -- fg
set_hl(0, "BlinkCmpKindConstant", { fg = "#bb9dbd" }) -- parameter
set_hl(0, "BlinkCmpKindClass", { fg = "#9bb4bc" }) -- type
set_hl(0, "BlinkCmpKindInterface", { fg = "#9bb4bc" }) -- type
set_hl(0, "BlinkCmpKindStruct", { fg = "#9bb4bc" }) -- type
set_hl(0, "BlinkCmpKindModule", { fg = "#b4d4cf" }) -- builtin teal
set_hl(0, "BlinkCmpKindField", { fg = "#bb9dbd" }) -- parameter
set_hl(0, "BlinkCmpKindProperty", { fg = "#bb9dbd" }) -- parameter
set_hl(0, "BlinkCmpKindEnum", { fg = "#f3be7c" }) -- warning amber
set_hl(0, "BlinkCmpKindEnumMember", { fg = "#f3be7c" }) -- warning amber
set_hl(0, "BlinkCmpKindSnippet", { fg = "#606079" }) -- comment / dimmed
set_hl(0, "BlinkCmpKindText", { fg = "#606079" }) -- comment / dimmed
