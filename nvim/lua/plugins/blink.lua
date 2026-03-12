-- ============================================================================
-- BLINK.CMP (completion engine)
-- Keymap and source config live here. Visual styling (borders, colours) is
-- handled via highlight group overrides in plugins/highlights.lua so it sits
-- alongside the rest of the post-colorscheme tweaks.
--
-- This module returns get_lsp_capabilities() so that plugins/lsp.lua can
-- merge blink's extra completion capabilities into its server configs without
-- either file having to reach into the other.
-- ============================================================================

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
			menu = {
				auto_show = true,
				-- draw = {
				-- 	columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
				-- },
			},
			ghost_text = { enabled = true },
		},
	},

	completion = {
		menu = {
			auto_show = true,
			-- Rounded border — matches the 8px border-radius on the Waybar window
			-- and the rounded borders used on all other floats (which-key, diagnostics).
			border = "rounded",
			-- Raised surface (#1c1c24) so the menu lifts off the buffer, same as
			-- how Waybar's bg-raised colour separates it from the desktop.
			winhighlight = "Normal:BlinkMenuNormal,FloatBorder:BlinkMenuBorder,CursorLine:BlinkMenuSel,Search:None",
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 100,
			window = {
				-- Same border + surface treatment as the completion menu so both
				-- panels read as a single coherent component.
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

-- ============================================================================
-- CAPABILITIES
-- Exposed so plugins/lsp.lua can call require("plugins.blink").capabilities()
-- to get blink-augmented LSP caps without duplicating the pcall logic.
-- ============================================================================
local function capabilities()
	local ok, blink = pcall(require, "blink.cmp")
	if ok then
		return blink.get_lsp_capabilities()
	end
	return vim.lsp.protocol.make_client_capabilities()
end

return { capabilities = capabilities }
