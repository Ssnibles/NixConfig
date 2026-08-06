local fzf = require("fzf-lua")

fzf.setup({
  winopts = {
    height = 0.85,
    width = 0.85,
    row = 0.50,
    col = 0.50,
    border = "rounded",
    backdrop = 100,
    preview = {
      layout = "flex",
      flip_columns = 100,
      vertical = "down:50%",
      horizontal = "right:50%",
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
  oldfiles = { include_current_session = false, cwd_only = true, stat_file = false },
  grep = { rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'" },
  keymap = {
    fzf = {
      ["ctrl-q"] = "select-all+accept",
      ["ctrl-/"] = "toggle-preview",
    },
  },
})

local map = vim.keymap.set

map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fo", fzf.oldfiles, { desc = "Recent files" })
map("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word" })
map("n", "<leader>fW", fzf.grep_cWORD, { desc = "Grep WORD" })
map("n", "<leader>f/", fzf.blines, { desc = "Search buffer" })
map("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Document symbols" })
map("n", "<leader>fS", fzf.lsp_workspace_symbols, { desc = "Workspace symbols" })
map("n", "<leader>fd", fzf.diagnostics_document, { desc = "Diagnostics" })
map("n", "<leader>fh", fzf.help_tags, { desc = "Help" })
map("n", "<leader>fk", fzf.keymaps, { desc = "Keymaps" })
map("n", "<leader>f.", fzf.resume, { desc = "Resume last picker" })

map("n", "<leader>gg", function()
  require("neogit").open()
end, { desc = "Neogit status" })
map("n", "<leader>gc", fzf.git_commits, { desc = "Git commits" })
map("n", "<leader>gS", fzf.git_status, { desc = "Git status (picker)" })
map("n", "<leader>gl", fzf.git_commits, { desc = "Git log" })
map("n", "<leader>gL", fzf.git_bcommits, { desc = "Git log (current file)" })
map("n", "<leader>gB", fzf.git_branches, { desc = "Git branches" })
map("n", "<leader>gF", fzf.git_stash, { desc = "Git stash" })
