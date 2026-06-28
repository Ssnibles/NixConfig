-- Neogit: git porcelain with polished Zed-inspired styling

local neogit = require("neogit")
neogit.setup({
	kind = "tab",
	disable_signs = false,
	disable_hint = true,
	disable_insert_on_commit = "auto",
	disable_commit_confirmation = true,
	graph_style = "unicode",
	auto_refresh = true,
	refresh_interval = 3000,

	signs = {
		hunk = { "", "" },
		item = { "▸", "▾" },
		section = { "▸", "▾" },
	},

	sections = {
		untracked = { folded = false, hidden = false },
		unstaged = { folded = false, hidden = false },
		staged = { folded = false, hidden = false },
		stash = { folded = true, hidden = false },
		unpulled_upstream = { folded = true, hidden = false },
		unmerged_upstream = { folded = false, hidden = false },
		unpulled_pushRemote = { folded = true, hidden = false },
		unmerged_pushRemote = { folded = false, hidden = false },
		recent = { folded = true, hidden = false },
		rebase = { folded = true, hidden = false },
	},

	integrations = { fzf_lua = true },

	popup = {
		kind = "split",
	},
	commit_popup = {
		kind = "split",
	},
	commit_view = {
		kind = "vsplit",
		verify_commit = false,
	},
	commit_editor = {
		kind = "vsplit",
		show_staged_diff = true,
	},
})
