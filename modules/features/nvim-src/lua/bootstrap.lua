local M = {}

--- Safely load a single module with error handling
local function load_one(module)
    local ok, err = pcall(require, module)
    if not ok then
        vim.schedule(function()
            vim.notify(
                string.format("Failed loading %s:\n%s", module, err),
                vim.log.levels.ERROR,
                { title = "Module Loader" }
            )
        end)
    end
    return ok
end

--- Safely iterate and load a table of module names
local function load_all(modules)
    if type(modules) ~= "table" then
        return
    end

    for _, module in ipairs(modules) do
        load_one(module)
    end
end

--- Load core modules immediately and deferred modules on VimEnter
function M.load_modules(core, deferred)
    load_all(core)

    if type(deferred) == "table" and #deferred > 0 then
        vim.api.nvim_create_autocmd("VimEnter", {
            group = vim.api.nvim_create_augroup("BootstrapDeferredLoader", { clear = true }),
            once = true,
            callback = function()
                if vim.v.exiting == nil or vim.v.exiting ~= 0 then
                    return
                end
                load_all(deferred)
            end,
        })
    end
end

return M
