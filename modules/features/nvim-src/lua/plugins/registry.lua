local M = {}

M.core = {
  "plugins.treesitter",
  "plugins.completion",
  "plugins.lsp",
  "plugins.editor",
  "plugins.format",
  "plugins.mini",
  "plugins.fzf",
  "plugins.navigation",
  "plugins.ui",
  "plugins.terminal",
  "plugins.lint",
  "plugins.rust",
  "plugins.sshinator",
  "plugins.indentinator",
  "plugins.java-snippets",
  "plugins.typst-snippets",
  "plugins.nix-snippets",
}

M.deferred = {
  "plugins.neogit",
  "plugins.dap",
}

return M
