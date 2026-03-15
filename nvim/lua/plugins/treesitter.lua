-- nvim-treesitter — syntax highlighting and smart indentation.
-- Parsers are installed via modules/neovim.nix (withPlugins), not here.

local ok, ts = pcall(require, "nvim-treesitter.configs")
if not ok then
	return
end

ts.setup({
	highlight = { enable = true },
	indent = { enable = true },
})
