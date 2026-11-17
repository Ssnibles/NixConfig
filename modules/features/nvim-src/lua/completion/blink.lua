-- Blink.cmp: menu, documentation, ghost text and the cmdline menu.

local cmp = require("blink.cmp")

local kind_icons = {
	Text = "󰉿",
	Method = "󰆧",
	Function = "󰊕",
	Constructor = "󰒓",
	Field = "󰜢",
	Variable = "󰀫",
	Class = "󰠱",
	Interface = "󱡠",
	Module = "󰅩",
	Property = "󰜢",
	Unit = "󰑭",
	Value = "󰎠",
	Enum = "󰦨",
	EnumMember = "󰦨",
	Keyword = "󰌋",
	Snippet = "󱄽",
	Color = "󰏘",
	File = "󰈙",
	Folder = "󰉋",
	Reference = "󰈇",
	Constant = "󰏿",
	Struct = "󰙅",
	Event = "󱐋",
	Operator = "󰆕",
	TypeParameter = "󰊄",
	Copilot = "",
}

local function cancel_if_visible(c)
	if c.is_visible() then
		c.cancel()
	end
end

cmp.setup({
	keymap = {
		preset = "none",
		["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
		["<CR>"] = { "fallback" },
		["<Tab>"] = { "select_and_accept", "fallback" },
		["<C-y>"] = { "select_and_accept", "fallback" },
		["<C-]>"] = { "snippet_forward", "fallback" },
		["<Esc>"] = { cancel_if_visible, "fallback" },
		["<C-c>"] = { cancel_if_visible, "fallback" },
		["<C-e>"] = { "cancel", "fallback" },
		["<Up>"] = { "select_prev", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<C-n>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },
	},
	signature = { enabled = true, window = { border = "rounded", show_documentation = true } },
	snippets = { preset = "luasnip" },
	appearance = { nerd_font_variant = "mono", kind_icons = kind_icons },
	fuzzy = {
		implementation = "prefer_rust",
		use_proximity = true,
		sorts = { "exact", "score", "sort_text" },
	},
	sources = require("completion.sources"),
	completion = {
		list = {
			selection = {
				preselect = function(ctx)
					return ctx.mode ~= "cmdline"
				end,
				auto_insert = false,
			},
		},
		menu = {
			auto_show = true,
			direction_priority = { "s", "n" },
			border = "rounded",
			scrollbar = true,
			draw = {
				padding = { 1, 1 },
				treesitter = { "lsp" },
				columns = { { "kind_icon", gap = 1 }, { "label", "label_description", gap = 1 }, { "kind" } },
			},
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 50,
			window = { border = "rounded", max_width = 80, max_height = 30 },
		},
		ghost_text = {
			enabled = true,
			show_with_selection = true,
			show_without_selection = false,
		},
	},
	cmdline = {
		keymap = {
			preset = "none",
			["<CR>"] = { "fallback" },
			["<Tab>"] = { "select_and_accept", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-e>"] = { "cancel", "fallback" },
			["<Esc>"] = false,
			["<C-c>"] = false,
		},
		completion = {
			-- The bar sits at the bottom, so open the menu above it.
			menu = { auto_show = true, direction_priority = { "n", "s" } },
			ghost_text = { enabled = true },
		},
	},
})

return cmp
