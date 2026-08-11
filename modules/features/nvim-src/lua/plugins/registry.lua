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
  "plugins.fidget",
  "plugins.terminal",
  "plugins.lint",
  "plugins.sshinator",
  "plugins.indentinator",
  "plugins.nix-snippets",
  "plugins.inc-rename",
  "plugins.typst-snippets",
  "plugins.java-snippets",
}

M.deferred = {
  "plugins.neogit",
  "plugins.dap",
  "plugins.rust",
}

return M
