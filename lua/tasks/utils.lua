local a = vim.api

local M = {}

function M.nil_if_error(fn)
    vim.validate("fn", fn, "function")
    return function(...)
        local ok, res = pcall(fn, ...)
        if ok then
            return res
        end
    end
end

function M.get_line()
    local row, _ = unpack(a.nvim_win_get_cursor(0))
    return a.nvim_buf_get_lines(0, row - 1, row, true)[1]
end

function M.set_line(line)
    vim.validate("line", line, "string")

    local row, _ = unpack(a.nvim_win_get_cursor(0))
    return a.nvim_buf_set_lines(0, row - 1, row, true, { line })
end

function M.get_utc(localtime)
    ---@diagnostic disable-next-line: param-type-mismatch
    local sgn, h_offset, m_offset = os.date("%z"):match("([+-])(%d%d)(%d%d)")
    if sgn == "+" then
        sgn = 1
    else
        sgn = -1
    end
    h_offset = tonumber(h_offset)
    m_offset = tonumber(m_offset)

    local offset = ((h_offset * 3600) + (m_offset * 60)) * sgn
    return (localtime or os.time()) - offset
end

---@return string
function M.get_huid()
    return tostring(os.date("%Y%m%d-%H%M%S", M.get_utc()))
end

function M.get_root_dir()
    return vim.fs.root(vim.uv.cwd(), ".git")
end

function M.get_database()
    local root_dir = M.get_root_dir()
    if root_dir then
        return vim.fs.joinpath(root_dir, "tasks")
    end
end

function M.get_task_path_by_huid(huid, create)
    vim.validate("huid", huid, "string")
    vim.validate("create", create, { "nil", "string" })

    local db = M.get_database()
    if not db then
        return vim.notify("Tasks: no database found", vim.log.levels.ERROR)
    end

    local task_path = vim.fs.joinpath(db, huid)
    local task_md_path = vim.fs.joinpath(task_path, "TASK.md")
    if not vim.uv.fs_stat(task_md_path) and type(create) == "string" then
        vim.fn.mkdir(task_path, "p")
        local handle = vim.uv.fs_open(task_md_path, "w", tonumber("644", 8))
        vim.uv.fs_write(handle, create)
        vim.uv.fs_close(handle)
    end

    return task_md_path
end

---@param absolute_path string
---@return string?
function M.get_task_title(absolute_path)
    if type(absolute_path) ~= "string" then
        return
    end
    local ok, res = pcall(function()
        return string.match(io.lines(absolute_path)(), "^# (.*)")
    end)
    if ok then
        return vim.trim(res)
    end
end

function M.get_task_field(field)
    return function(absolute_path)
        if type(absolute_path) ~= "string" then
            return
        end
        for line in io.lines(absolute_path) do
            local match = string.match(line, ("^- %s: (.*)"):format(field))
            if match then
                return vim.trim(match)
            end
        end
    end
end

M.get_task_priority = M.nil_if_error(M.get_task_field("PRIORITY"))
M.get_task_state = M.nil_if_error(M.get_task_field("STATE"))

function M.spawn_output(prog, args, cb)
    local stdout = vim.uv.new_pipe()
    local output = ""
    vim.uv.spawn(prog, {
        args = args,
        stdio = { nil, stdout, nil },
    }, function(code, signal)
        if code ~= 0 or signal ~= 0 then
            return error(
                ("Process %s with args %s exited with exit code %d and signal %d"):format(
                    prog,
                    vim.inspect(args),
                    code,
                    signal
                )
            )
        end
        cb(output)
    end)
    vim.uv.read_start(stdout, function(err, data)
        assert(not err, err)
        if data then
            output = output .. data
        end
    end)
end

---@param bl tasks.Backlink
---@return string
function M.pretty_print_backlink(bl)
    return ("%s:%d:%d: %s"):format(bl.filename, bl.lnum, bl.col, bl.text)
end

return M
