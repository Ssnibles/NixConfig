-- Treesitter: syntax highlighting and text objects

-- Work around Neovim 0.12 occasional stale-node reads during destructive edits.
if vim.version().major == 0 and vim.version().minor >= 12 then
	do
		if not vim.g.__treesitter_safe_get_node_text then
			vim.g.__treesitter_safe_get_node_text = true
			local original_get_node_text = vim.treesitter.get_node_text
			local function is_transient_treesitter_node_error(msg)
				return msg:find("Index out of bounds", 1, true)
					or msg:find("attempt to call method 'range' (a nil value)", 1, true)
			end
			vim.treesitter.get_node_text = function(node, source, opts)
				local ok, result = pcall(original_get_node_text, node, source, opts)
				if ok then
					return result
				end
				local msg = tostring(result)
				if is_transient_treesitter_node_error(msg) then
					return ""
				end
				error(result)
			end
		end
	end
end

require("nvim-treesitter.configs").setup({
	highlight = {
		enable = true,
		disable = { "markdown", "markdown_inline" },
		additional_vim_regex_highlighting = { "markdown" },
	},
	indent = { enable = true },
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
			goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
		},
	},
})

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

-- Work around occasional extmark range errors from treesitter-context (0.12+).
if vim.version().major == 0 and vim.version().minor >= 12 then
	do
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
end
