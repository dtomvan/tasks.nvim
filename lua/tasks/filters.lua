local M = {}

function M.is_open(t)
    vim.validate("t", t, "table")
    vim.validate("t.state", t.state, "string")
    return t.state ~= "CLOSED"
end

return M
