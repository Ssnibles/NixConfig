-- LuaSnip: history, region checks, and the two snippet libraries.

local ls = require("luasnip")

ls.setup({
	history = true,
	region_check_events = "InsertEnter,TextChangedI",
	delete_check_events = "InsertLeave",
})

require("luasnip.loaders.from_vscode").lazy_load()
-- Snippets live outside lua/ because they are data. A subdirectory of the root
-- would be read as a filetype name.
require("luasnip.loaders.from_lua").lazy_load({
	paths = { vim.fn.stdpath("config") .. "/snippets" },
})

vim.keymap.set("s", "<C-]>", function()
	if ls.locally_jumpable(1) then
		ls.jump(1)
	end
end, { desc = "Snippet forward", silent = true })

return ls
