local M = {}

local function require_check(rq, advice)
    local ok, _ = pcall(require, rq)

    if ok then
        vim.health.ok(("require `%s`"):format(rq))
    else
        vim.health.warn(("Failed to require `%s`"):format(rq), advice)
    end
end

function M.check()
    vim.health.start("tasks")
    if vim.fn.executable("git") == 1 then
        vim.health.ok("Git available")
    else
        vim.health.warn("Git not installed", "Install git for backlinks functionality")
    end
    require_check("telescope", "Install for searching through tasks")
    require_check("cmp", "Install for autocompleting HUIDs")
end

return M
