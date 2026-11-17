-- Insert-mode <CR> handling: continue lists, and let mini.pairs handle the
-- space between a pair. Comment continuation is the built-in 'formatoptions'
-- 'r' flag, not a reimplementation.

local M = {}
local list_filetypes = {
	markdown = true,
	["markdown.mdx"] = true,
	pandoc = true,
	rmd = true,
	quarto = true,
	typst = true,
	text = true,
	txt = true,
	gitcommit = true,
}
local comment_prefixes = { "//", "/*", "*", "#", ";", "!", "%%", "--" }

--- @param line string
--- @param ft string
--- @return table|nil
local function list_item(line, ft)
	-- Checkbox: "- [ ] ", "* [x] ", "+ [ ] ".
	local indent, marker, sep, box, space, rest = line:match("^([ \t]*)([-*+])(%s+)(%[[%sxX ]%])(%s*)(.*)$")
	if indent then
		return {
			empty = space == "" or rest == "",
			marker_end = #indent + #marker + #sep + #box + #space,
			next_marker = marker .. " [ ] ",
		}
	end
	-- Numbered: "1. ", "10) ".
	indent, marker, sep, space, rest = line:match("^([ \t]*)(%d+)([.)])(%s*)(.*)$")
	if indent then
		return {
			empty = space == "" or rest == "",
			marker_end = #indent + #marker + #sep + #space,
			next_marker = tostring(tonumber(marker) + 1) .. sep .. " ",
		}
	end
	-- Typst auto-numbered list.
	if ft == "typst" then
		indent, space, rest = line:match("^([ \t]*)%+(%s*)(.*)$")
		if indent then
			return { empty = space == "" or rest == "", marker_end = #indent + 1 + #space, next_marker = "+ " }
		end
	end
	-- Bullets. In Typst only "-" is a bullet; "*" is bold.
	local pattern = ft == "typst" and "^([ \t]*)(%-)(%s*)(.*)$" or "^([ \t]*)([-*+])(%s*)(.*)$"
	indent, marker, space, rest = line:match(pattern)
	if indent then
		-- Horizontal rules are not list items.
		if line:match("^%s*[-*_]%s*[-*_]%s*[-*_][%s*-_]*$") then
			return nil
		end
		return {
			empty = space == "" or rest == "",
			marker_end = #indent + #marker + #space,
			next_marker = marker .. " ",
		}
	end
end

local function is_comment(line)
	for _, prefix in ipairs(comment_prefixes) do
		if line:find("^%s*" .. vim.pesc(prefix)) then
			return true
		end
	end
	return false
end

local function keys(sequence)
	return vim.api.nvim_replace_termcodes(sequence, true, false, true)
end

--- <CR> in insert mode.
--- @return string
function M.cr()
	local ft = vim.bo.filetype
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local pair_cr = require("mini.pairs").cr()
	if pair_cr ~= "\r" and pair_cr ~= "<CR>" then
		return pair_cr
	end
	if list_filetypes[ft] then
		local item = list_item(line, ft)
		if item then
			if item.empty then
				return keys("<C-u>")
			end
			if col >= item.marker_end or col >= #line then
				return keys("<CR>" .. item.next_marker)
			end
		end
	end
	return keys("<CR>")
end

--- <S-CR> in insert mode: a new line without list or comment continuation.
--- @return string
function M.plain_cr()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	if col >= #line then
		return keys("<C-o>o")
	end
	if is_comment(line) then
		return keys("<CR><C-u>" .. (line:match("^[ \t]*") or ""))
	end
	return keys("<CR>")
end

return M
