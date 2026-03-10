-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================
local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 }) end,
})

-- Diagnostic Line Number Highlights
local diag_ns = vim.api.nvim_create_namespace("diag_linenum_hl")
local severity_hl = {
  [vim.diagnostic.severity.ERROR] = { sign = "DiagnosticSignError", line = "DiagnosticVirtualTextError" },
  [vim.diagnostic.severity.WARN]  = { sign = "DiagnosticSignWarn", line = "DiagnosticVirtualTextWarn" },
  [vim.diagnostic.severity.INFO]  = { sign = "DiagnosticSignInfo", line = "DiagnosticVirtualTextInfo" },
  [vim.diagnostic.severity.HINT]  = { sign = "DiagnosticSignHint", line = "DiagnosticVirtualTextHint" },
}

local function update_diag_linenum_hl(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, diag_ns, 0, -1)

  local line_severity = {}
  for _, diag in ipairs(vim.diagnostic.get(bufnr)) do
    if not line_severity[diag.lnum] or diag.severity < line_severity[diag.lnum] then
      line_severity[diag.lnum] = diag.severity
    end
  end

  for line, severity in pairs(line_severity) do
    local hl = severity_hl[severity]
    vim.api.nvim_buf_set_extmark(bufnr, diag_ns, line, 0, {
      number_hl_group = hl.sign,
      line_hl_group = hl.line,
    })
  end
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
  group = group,
  callback = function(ev) update_diag_linenum_hl(ev.buf) end,
})

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
