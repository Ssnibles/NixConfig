-- Treesitter: syntax highlighting and text objects

if require("version") then
	if not vim.g.__treesitter_safe_get_node_text then
		vim.g.__treesitter_safe_get_node_text = true
		local original_get_node_text = vim.treesitter.get_node_text
		vim.treesitter.get_node_text = function(node, source, opts)
			local ok, result = pcall(original_get_node_text, node, source, opts)
			if ok then
				return result
			end
			local msg = tostring(result)
			if msg:find("Index out of bounds", 1, true)
				or msg:find("attempt to call method 'range' (a nil value)", 1, true)
			then
				return ""
			end
			error(result)
		end
	end

	if not vim.g.__treesitter_safe_start then
		vim.g.__treesitter_safe_start = true
		local original_start = vim.treesitter.start
		vim.treesitter.start = function(bufnr, lang)
			local ok, result = pcall(original_start, bufnr, lang)
			if ok then
				return result
			end
			local msg = tostring(result)
			if msg:find("Parser could not be created", 1, true)
				or msg:find("Parser not found", 1, true) then
				return false
			end
			error(result)
		end
	end
end

-- Treesitter highlighting and indentation are built-in in Neovim 0.12.
-- Markdown disable and prose settings are handled by autocmds.lua.

-- Textobjects: select and move
require("nvim-treesitter-textobjects").setup({
	select = { lookahead = true },
	move = { set_jumps = true },
})

local ts_select = require("nvim-treesitter-textobjects.select")
local ts_move = require("nvim-treesitter-textobjects.move")

local select_keymaps = {
	["af"] = { query = "@function.outer", desc = "Around function" },
	["if"] = { query = "@function.inner", desc = "Inside function" },
	["ac"] = { query = "@class.outer", desc = "Around class" },
	["ic"] = { query = "@class.inner", desc = "Inside class" },
	["aa"] = { query = "@parameter.outer", desc = "Around parameter" },
	["ia"] = { query = "@parameter.inner", desc = "Inside parameter" },
}
for key, spec in pairs(select_keymaps) do
	vim.keymap.set({ "o", "x" }, key, function()
		ts_select.select_textobject(spec.query)
	end, { silent = true, desc = spec.desc })
end

vim.keymap.set({ "n", "o", "x" }, "]f", function()
	ts_move.goto_next_start("@function.outer")
end, { silent = true, desc = "Next function" })
vim.keymap.set({ "n", "o", "x" }, "[f", function()
	ts_move.goto_previous_start("@function.outer")
end, { silent = true, desc = "Previous function" })
vim.keymap.set({ "n", "o", "x" }, "]c", function()
	ts_move.goto_next_start("@class.outer")
end, { silent = true, desc = "Next class" })
vim.keymap.set({ "n", "o", "x" }, "[c", function()
	ts_move.goto_previous_start("@class.outer")
end, { silent = true, desc = "Previous class" })

-- Treesitter context: sticky headers
require("treesitter-context").setup({
	enable = true,
	max_lines = 4,
	min_window_height = 20,
	separator = "─",
	on_attach = function(buf)
		local ft = vim.bo[buf].filetype
		return ft ~= "markdown" and ft ~= "markdown.mdx"
	end,
})

-- Work around occasional extmark range errors from treesitter-context (Neovim 0.12 only).
if require("version") then
	local ok, render = pcall(require, "treesitter-context.render")
	if ok and type(render.open) == "function" then
		local original_open = render.open
		render.open = function(...)
			local ok_open, result = pcall(original_open, ...)
			if not ok_open then
				local msg = tostring(result)
				if msg:find("Invalid 'end_col': out of range", 1, true) then
					return
				end
				error(result)
			end
			return result
		end
	end
end
