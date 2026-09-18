local M = {}

-- Filetypes that support markdown/typst-style list continuation
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

--- Analyzes the current line to see if it represents a list item
--- @param line string
--- @param ft string
--- @return table|nil
local function get_list_item(line, ft)
  -- 1. Checkbox list: "- [ ] ", "- [x] ", "* [ ] ", "+ [ ] "
  local c_indent, c_marker, c_box, c_space, c_rest = line:match("^([ \t]*)([-*+])%s+(%[[%sxX ]%])(%s*)(.*)$")
  if c_indent and c_marker and c_box then
    local is_empty = (c_space == "" or c_rest == "")
    return {
      indent = c_indent,
      is_empty = is_empty,
      marker_end = #c_indent + #c_marker + 1 + #c_box + #c_space,
      continuation_marker = c_marker .. " [ ] ",
    }
  end

  -- 2. Numbered list: "1. ", "10. ", "1) "
  local n_indent, num, delim, n_space, n_rest = line:match("^([ \t]*)(%d+)([.)])(%s*)(.*)$")
  if n_indent and num and delim then
    local is_empty = (n_space == "" or n_rest == "")
    local next_num = tostring(tonumber(num) + 1)
    return {
      indent = n_indent,
      is_empty = is_empty,
      marker_end = #n_indent + #num + #delim + #n_space,
      continuation_marker = next_num .. delim .. " ",
    }
  end

  -- 3. Typst auto-numbered list: "+ "
  if ft == "typst" then
    local t_indent, t_space, t_rest = line:match("^([ \t]*)%+(%s*)(.*)$")
    if t_indent then
      local is_empty = (t_space == "" or t_rest == "")
      return {
        indent = t_indent,
        is_empty = is_empty,
        marker_end = #t_indent + 1 + #t_space,
        continuation_marker = "+ ",
      }
    end
  end

  -- 4. Unordered bullet list:
  -- In Typst, only "-" is a bullet ("*" is bold).
  -- In markdown/others, "-", "*", "+" are bullets.
  local b_indent, b_marker, b_space, b_rest
  if ft == "typst" then
    b_indent, b_marker, b_space, b_rest = line:match("^([ \t]*)(%-)(%s*)(.*)$")
  else
    b_indent, b_marker, b_space, b_rest = line:match("^([ \t]*)([-*+])(%s*)(.*)$")
  end

  if b_indent and b_marker then
    -- Ignore markdown thematic breaks / horizontal rules (e.g. "---", "***")
    if line:match("^%s*[-*_]%s*[-*_]%s*[-*_][%s*-_]*$") then
      return nil
    end

    local is_empty = (b_space == "" or b_rest == "")
    return {
      indent = b_indent,
      is_empty = is_empty,
      marker_end = #b_indent + #b_marker + #b_space,
      continuation_marker = b_marker .. " ",
    }
  end

  return nil
end

--- Checks if a line is a comment in code
--- @param line string
--- @param ft string
--- @return boolean
local function is_comment_line(line, ft)
  if list_filetypes[ft] and get_list_item(line, ft) then
    return false
  end
  return line:match("^%s*([/%*#;!%-%-])") ~= nil
end

--- Handler for <CR> in insert mode
--- Continues lists (markdown, typst, etc.) and block comments / doc comments
function M.cr()
  local ft = vim.bo.filetype
  local line = vim.api.nvim_get_current_line()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- 1. If cursor is between matching pairs, let mini.pairs expand them
  if _G.MiniPairs ~= nil and type(_G.MiniPairs.cr) == "function" then
    local pair_res = _G.MiniPairs.cr()
    if pair_res ~= "\r" and pair_res ~= "<CR>" then
      return pair_res
    end
  end

  -- 2. Check if the current line is a list item
  if list_filetypes[ft] then
    local item = get_list_item(line, ft)
    if item then
      if item.is_empty then
        -- Empty list item: clear the bullet/number and leave an empty line
        return vim.api.nvim_replace_termcodes("<C-u>", true, false, true)
      end

      -- If cursor is after the prefix, continue the list
      if col >= item.marker_end or col >= #line then
        return vim.api.nvim_replace_termcodes("<CR>" .. item.continuation_marker, true, false, true)
      end
    end
  end

  -- 3. Default Enter: triggers formatoptions 'r' (block comments, line comments)
  -- or normal newline with autoindent
  return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
end

--- Handler for <S-CR> in insert mode: "just put the line down"
--- Creates a new line WITHOUT continuing lists or comments
function M.shift_cr()
  local ft = vim.bo.filetype
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  if col >= #line then
    -- Cursor is at end of line: <C-o>o opens a new line without formatoptions comment continuation
    -- (since formatoptions has -o)
    return vim.api.nvim_replace_termcodes("<C-o>o", true, false, true)
  end

  -- Cursor is in the middle of a line
  if is_comment_line(line, ft) then
    local indent = line:match("^[ \t]*") or ""
    return vim.api.nvim_replace_termcodes("<CR><C-u>" .. indent, true, false, true)
  else
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end
end

return M
