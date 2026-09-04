-- User configuration
local CONFIG = {
  filetypes = {
    nix = { "deadnix_nvim", "statix_nvim" },
    c = { "cppcheck" },
    cpp = { "cppcheck" },
  },
  -- Reduced from BufEnter/InsertLeave to avoid screen flashing & diagnostic redraws
  autocmd_events = { "BufWritePost", "BufReadPost" },
}

local lint = require("lint")

-- Parses deadnix JSON array output into Neovim diagnostic tables
local function parse_deadnix(output)
  local ok, decoded = pcall(vim.json.decode, output)
  if not ok or type(decoded) ~= "table" then return {} end

  local diagnostics = {}
  for _, file_entry in ipairs(decoded) do
    for _, item in ipairs(file_entry.results or {}) do
      local line = math.max((item.line or 1) - 1, 0)
      local col = math.max((item.column or 1) - 1, 0)
      local end_col = math.max((item.endColumn or (col + 1)) - 1, col + 1)

      diagnostics[#diagnostics + 1] = {
        lnum = line,
        end_lnum = line,
        col = col,
        end_col = end_col,
        severity = vim.diagnostic.severity.WARN,
        source = "deadnix",
        message = item.message or "Unused Nix code",
      }
    end
  end
  return diagnostics
end

lint.linters.deadnix_nvim = {
  cmd = "deadnix",
  stdin = false,
  append_fname = true,
  args = { "-o", "json" },
  parser = parse_deadnix,
}

-- Parses statix errfmt output (path>line:col:severity:code:message)
local function parse_statix_errfmt(output, bufnr)
  local diagnostics = {}
  local cur_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")

  for line in output:gmatch("[^\r\n]+") do
    local path, lnum, col, severity_letter, code, message =
        line:match("^([^>]+)>(%d+):(%d+):([WE]):(%d+):(.*)$")

    if path and message then
      if vim.fn.fnamemodify(path, ":p") == cur_path then
        local line_num = math.max(tonumber(lnum) - 1, 0)
        local col_num = math.max(tonumber(col) - 1, 0)

        diagnostics[#diagnostics + 1] = {
          lnum = line_num,
          end_lnum = line_num,
          col = col_num,
          end_col = col_num + 1,
          severity = severity_letter == "E" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
          source = "statix",
          code = code,
          message = vim.trim(message),
        }
      end
    end
  end
  return diagnostics
end

lint.linters.statix_nvim = {
  cmd = "statix",
  stdin = false,
  append_fname = true,
  args = { "check", "--format", "errfmt" },
  parser = parse_statix_errfmt,
  ignore_exitcode = true,
}

lint.linters_by_ft = CONFIG.filetypes

-- Runs active linters if configured for current filetype and file exists on disk
local function run_lint()
  local ft = vim.bo.filetype
  if CONFIG.filetypes[ft] then
    -- Skip running CLI linters on unsaved buffers to prevent stale diagnostics
    if vim.bo.modified and vim.api.nvim_buf_get_name(0) == "" then return end
    lint.try_lint()
  end
end

-- Autocommand to run linters on buffer read and save
local lint_augroup = vim.api.nvim_create_augroup("UserLint", { clear = true })
vim.api.nvim_create_autocmd(CONFIG.autocmd_events, {
  group = lint_augroup,
  callback = run_lint,
})

-- Manual lint trigger mapping
vim.keymap.set("n", "<leader>cL", function()
  run_lint()
  vim.notify("Triggered linters for " .. vim.bo.filetype, vim.log.levels.INFO)
end, { desc = "Lint buffer" })
