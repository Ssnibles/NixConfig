local function test()
    local mode = vim.api.nvim_get_mode().mode
    local first = mode:sub(1, 1)
    local is_insert_or_visual = first == "i" or first == "v" or first == "V" or first == "\22"
    print("Mode: " .. mode .. ", First: " .. first .. ", IsInsertOrVisual: " .. tostring(is_insert_or_visual))
end

vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*:*",
    callback = test,
})
