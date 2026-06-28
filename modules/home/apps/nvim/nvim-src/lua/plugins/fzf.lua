-- fzf-lua: universal palette -- tight, centred, and modern.

local fzf = require("fzf-lua")
fzf.setup({
	winopts = {
		height = 0.85,
		width = 0.80,
		row = 0.50,
		col = 0.50,
		border = "rounded",
		backdrop = 100,
		preview = {
			layout = "vertical",
			vertical = "right:50%",
			border = "rounded",
			title = false,
		},
	},
	hl = {
		normal = "FzfLuaNormal",
		border = "FzfLuaBorder",
		preview_normal = "FzfLuaPreviewNormal",
		preview_border = "FzfLuaPreviewBorder",
		help_normal = "FzfLuaNormal",
		help_border = "FzfLuaBorder",
		cursor = "FzfLuaCursor",
		cursorline = "CursorLine",
	},
	previewers = {
		builtin = {
			render_markdown = false,
			treesitter = {
				enabled = true,
				disabled = { "markdown", "markdown_inline" },
				context = false,
			},
		},
	},
	files = { cmd = "fd --type f --hidden --exclude .git" },
	oldfiles = { include_current_session = true, cwd_only = true },
	grep = { rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'" },
	keymap = {
		fzf = {
			["ctrl-q"] = "select-all+accept",
			["ctrl-/"] = "toggle-preview",
		},
	},
})

local function responsive()
	local width = vim.api.nvim_win_get_width(0)
	if width < 110 then
		return {
			winopts = {
				preview = {
					layout = "horizontal",
					horizontal = "down:35%",
					border = "rounded",
					title = false,
				},
			},
		}
	end
	return {
		winopts = {
			preview = {
				layout = "vertical",
				vertical = "right:50%",
				border = "rounded",
				title = false,
			},
		},
	}
end

local function files()     fzf.files(responsive()) end
local function grep()      fzf.live_grep(responsive()) end
local function oldfiles()  fzf.oldfiles(responsive()) end
local function buffers()   fzf.buffers(responsive()) end
local function blines()    fzf.blines(responsive()) end
local function grep_cword()  fzf.grep_cword(responsive()) end
local function grep_cWORD()  fzf.grep_cWORD(responsive()) end
local function lsp_syms()    fzf.lsp_document_symbols(responsive()) end
local function lsp_wsyms()   fzf.lsp_workspace_symbols(responsive()) end
local function lsp_diag()    fzf.diagnostics_document(responsive()) end
local function help_tags()   fzf.help_tags(responsive()) end
local function keymaps()     fzf.keymaps(responsive()) end
local function resume()      fzf.resume() end
local function git_commits() fzf.git_commits(responsive()) end
local function git_status()  fzf.git_status(responsive()) end

local map = vim.keymap.set

-- ═══════════════════════════════════════════════════════════════════
--  F I N D   (<leader>f)
-- ═══════════════════════════════════════════════════════════════════

map("n", "<leader>ff", files, { desc = "Find files" })
map("n", "<leader>fo", oldfiles, { desc = "Recent files" })
map("n", "<leader>fb", buffers, { desc = "Buffers" })
map("n", "<leader>fg", grep, { desc = "Live grep" })
map("n", "<leader>fw", grep_cword, { desc = "Grep word" })
map("n", "<leader>fW", grep_cWORD, { desc = "Grep WORD" })
map("n", "<leader>f/", blines, { desc = "Search buffer" })
map("n", "<leader>fs", lsp_syms, { desc = "Document symbols" })
map("n", "<leader>fS", lsp_wsyms, { desc = "Workspace symbols" })
map("n", "<leader>fd", lsp_diag, { desc = "Diagnostics" })
map("n", "<leader>fh", help_tags, { desc = "Help" })
map("n", "<leader>fk", keymaps, { desc = "Keymaps" })
map("n", "<leader>f.", resume, { desc = "Resume last picker" })

-- ═══════════════════════════════════════════════════════════════════
--  G I T   (<leader>g)  -- consolidated
-- ═══════════════════════════════════════════════════════════════════

map("n", "<leader>gg", function()
	require("neogit").open()
end, { desc = "Neogit status" })
map("n", "<leader>gc", git_commits, { desc = "Git commits" })
map("n", "<leader>gS", git_status, { desc = "Git status (picker)" })
map("n", "<leader>gl", function()
	fzf.git_log({ winopts = responsive().winopts })
end, { desc = "Git log" })
map("n", "<leader>gL", function()
	fzf.git_log_line({ winopts = responsive().winopts })
end, { desc = "Git log (current line)" })
map("n", "<leader>gB", function()
	fzf.git_branches({ winopts = responsive().winopts })
end, { desc = "Git branches" })
map("n", "<leader>gF", function()
	fzf.git_stash({ winopts = responsive().winopts })
end, { desc = "Git stash" })
