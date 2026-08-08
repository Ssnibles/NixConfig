-- User configuration options
local CONFIG = {
    yank_highlight_timeout = 200,
    large_file_size_mb = 5,

    -- Filetypes to skip when trimming trailing whitespace on save
    trim_whitespace_skip_ft = {
        markdown = true,
        text = true,
        gitcommit = true,
        diff = true,
    },

    -- Filetypes closed by pressing 'q' or '<Esc>'
    close_with_q_ft = {
        "help",
        "man",
        "qf",
        "lspinfo",
        "checkhealth",
        "notify",
        "oil",
        "grug-far",
        "NeogitStatus",
        "cargo",
    },

    -- Filetypes with indent folding disabled by default
    fold_indent_ft = {
        "markdown",
        "markdown.mdx",
        "text",
        "gitcommit",
        "typst",
        "txt",
        "yaml",
        "json",
        "toml",
    },
}

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Trims trailing whitespace and empty lines on save
local function trim_trailing_whitespace()
    if vim.bo.buftype ~= "" or CONFIG.trim_whitespace_skip_ft[vim.bo.filetype] then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local modified = false

    -- Trim trailing whitespace per line
    for i, line in ipairs(lines) do
        local new_line = line:gsub("%s+$", "")
        if new_line ~= line then
            lines[i] = new_line
            modified = true
        end
    end

    -- Trim trailing blank lines at end of file
    local last = #lines
    while last > 1 and lines[last]:match("^%s*$") do
        last = last - 1
    end

    if last < #lines and #lines > 1 then
        for i = #lines, last + 1, -1 do
            table.remove(lines, i)
        end
        modified = true
    end

    if modified then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end
end

-- Trims trailing whitespace before writing to disk
autocmd("BufWritePre", {
    group = augroup,
    callback = trim_trailing_whitespace,
})

-- Automatically enables LSP inlay hints once attached
autocmd("LspAttach", {
    group = augroup,
    callback = function(args)
        if vim.lsp.inlay_hint and not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }) then
            pcall(vim.lsp.inlay_hint.enable, true, { bufnr = args.buf })
        end
    end,
})

-- Highlights yanked text briefly
autocmd("TextYankPost", {
    group = augroup,
    callback = function()
        vim.hl.on_yank({ timeout = CONFIG.yank_highlight_timeout })
    end,
})

-- Checks if files were changed outside Neovim when window gains focus
autocmd("FocusGained", {
    group = augroup,
    command = "checktime",
})

-- Restores cursor to last known position when opening a buffer
autocmd("BufReadPost", {
    group = augroup,
    callback = function(ev)
        local ft = vim.bo[ev.buf].filetype
        if ft == "gitcommit" or ft == "gitrebase" then
            return
        end

        local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(ev.buf)
        if mark[1] > 0 and mark[1] <= line_count then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Binds 'q' and '<Esc>' to close utility windows
autocmd("FileType", {
    group = augroup,
    pattern = CONFIG.close_with_q_ft,
    callback = function(ev)
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
        vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
    end,
})

-- Equalises window splits when Neovim window is resized
autocmd("VimResized", {
    group = augroup,
    command = "wincmd =",
})

-- Disables automatic comment insertion on new lines
autocmd("FileType", {
    group = augroup,
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})

-- Enables spell checking and line wrap for prose filetypes
autocmd("FileType", {
    group = augroup,
    pattern = { "markdown", "markdown.mdx", "text", "gitcommit" },
    callback = function(ev)
        vim.opt_local.spell = true
        vim.opt_local.wrap = true
        if vim.fn.has("nvim-0.12") == 1 then
            if vim.bo[ev.buf].filetype == "markdown" or vim.bo[ev.buf].filetype == "markdown.mdx" then
                pcall(vim.treesitter.stop, ev.buf)
            end
        end
    end,
})

-- Ensures signcolumn remains visible across window buffers
autocmd("BufWinEnter", {
    group = augroup,
    callback = function()
        local bt = vim.bo.buftype
        if bt == "terminal" or bt == "nofile" or bt == "acwrite" then
            return
        end
        if vim.wo.signcolumn == "no" then
            vim.wo.signcolumn = vim.o.signcolumn
        end
    end,
})

-- Switches to absolute line numbers in Insert and Visual modes
autocmd({ "ModeChanged", "BufEnter" }, {
    group = augroup,
    pattern = "*",
    callback = function()
        local bt = vim.bo.buftype
        if bt == "terminal" or bt == "nofile" or bt == "prompt" or bt == "quickfix" then
            return
        end

        local mode = vim.v.event.new_mode or vim.api.nvim_get_mode().mode
        local first = mode:sub(1, 1)
        local is_insert_or_visual = (first == "i" or first == "v" or first == "V" or first == "\22")

        vim.opt_local.number = true
        vim.opt_local.relativenumber = not is_insert_or_visual
    end,
})

-- Toggles cursorline highlighting based on focused window
autocmd("WinEnter", {
    group = augroup,
    callback = function()
        if vim.bo.buftype ~= "terminal" then
            vim.opt_local.cursorline = true
        end
    end,
})
autocmd("WinLeave", {
    group = augroup,
    callback = function()
        if vim.bo.buftype ~= "terminal" then
            vim.opt_local.cursorline = false
        end
    end,
})

-- Sets indent foldmethod for structured text formats
autocmd("FileType", {
    group = augroup,
    pattern = CONFIG.fold_indent_ft,
    callback = function()
        vim.opt_local.foldmethod = "indent"
        vim.opt_local.foldenable = false
    end,
})

-- Sets keywordprg to Neovim help for Lua and Vimscript
autocmd("FileType", {
    group = augroup,
    pattern = { "lua", "vim" },
    callback = function()
        vim.bo.keywordprg = ":help"
    end,
})

-- Configures Typst preview and Zathura sync keymaps
autocmd("FileType", {
    group = augroup,
    pattern = "typst",
    callback = function(ev)
        vim.keymap.set("n", "<leader>tp", function()
            vim.cmd("TypstPreviewToggle")
        end, { buffer = ev.buf, desc = "Toggle Typst preview" })

        vim.keymap.set("n", "<leader>zo", function()
            local pdf_path = vim.fn.expand("%:p:r") .. ".pdf"
            local buf_path = vim.api.nvim_buf_get_name(ev.buf)

            if vim.fn.filereadable(pdf_path) == 1 then
                vim.system({
                    "zathura",
                    "--synctex-forward=" .. vim.fn.line(".") .. ":0:" .. buf_path,
                    pdf_path,
                }, { detach = true })
            else
                vim.notify("PDF not found: " .. pdf_path, vim.log.levels.WARN)
            end
        end, { buffer = ev.buf, desc = "Open PDF in Zathura" })
    end,
})

-- Disables heavy syntax highlighting and folding for large files
autocmd("BufReadPost", {
    group = augroup,
    callback = function(ev)
        local path = vim.api.nvim_buf_get_name(ev.buf)
        if vim.bo[ev.buf].buftype ~= "" or path == "" then
            return
        end

        local ok, stat = pcall(vim.uv.fs_stat, path)
        if ok and stat and (stat.size / (1024 * 1024)) > CONFIG.large_file_size_mb then
            vim.b[ev.buf].large_file = true
            vim.opt_local.foldmethod = "manual"
            vim.opt_local.foldenable = false
            vim.bo[ev.buf].syntax = ""
        end
    end,
})

vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = augroup,
    pattern = "*",
    callback = function(ev)
        local success, err = pcall(function()
            -- Execute write silently without triggering hit-enter prompts
            vim.cmd("silent! lockmarks write!")
        end)

        if not success then
            vim.api.nvim_echo({ { "Save Failed: " .. tostring(err), "ErrorMsg" } }, true, {})
        else
            -- Force a screen refresh to clear any command-line status messages
            vim.cmd("redraw!")
            vim.api.nvim_buf_set_var(ev.buf, "changed", 0)
        end
    end,
})

