local M = {}

function M.is_open(t)
    vim.validate("t", t, "table")
    vim.validate("t.state", t.state, "string")
    return t.state ~= "CLOSED"
end

function M.is_closed(t)
    return not M.is_open(t)
end

return M
