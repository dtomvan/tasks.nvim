local a = vim.api

local M = {}

function M.get_line()
    local row, _ = unpack(a.nvim_win_get_cursor(0))
    return a.nvim_buf_get_lines(0, row - 1, row, true)[1]
end

function M.set_line(line)
    vim.validate("line", line, "string")

    local row, _ = unpack(a.nvim_win_get_cursor(0))
    return a.nvim_buf_set_lines(0, row - 1, row, true, { line })
end

function M.get_huid()
    return os.date("%Y%m%d-%H%M%S")
end

function M.get_database()
    local root_dir = vim.fs.root(0, ".git")
    if root_dir then
        return vim.fs.joinpath(root_dir, "tasks")
    end
end

function M.get_task_path_by_huid(huid, create)
    vim.validate("huid", huid, "string")
    vim.validate("create", create, { "nil", "boolean" })

    local db = M.get_database()
    if not db then
        return vim.notify("Tasks: no database found", vim.log.levels.ERROR)
    end

    local task_path = vim.fs.joinpath(db, huid)
    local task_md_path = vim.fs.joinpath(task_path, "TASK.md")
    if not vim.uv.fs_stat(task_md_path) and (create or false) then
        vim.fn.mkdir(task_path, "p")
        local handle = vim.uv.fs_open(task_md_path, "w", tonumber("644", 8))
        vim.uv.fs_write(handle, "")
        vim.uv.fs_close(handle)
    end

    return task_md_path
end

function M.get_task_title(absolute_path)
    return string.match(io.lines(absolute_path)(), "^# (.*)")
end

function M.get_task_field(field)
    return function(absolute_path)
        for line in io.lines(absolute_path) do
            local match = string.match(line, ("^- %s: (.*)"):format(field))
            if match then
                return match
            end
        end
    end
end

M.get_task_priority = M.get_task_field("PRIORITY")
M.get_task_state = M.get_task_field("STATE")

function M.create_task(opts)
    vim.validate("opts.title", opts.title, "string")
    vim.validate("opts.huid", opts.huid, { "nil", "string" })

    local task_file = M.get_task_path_by_huid(opts.huid or M.get_huid(), true)
    vim.cmd.split(task_file)
    vim.schedule(function()
        a.nvim_buf_set_lines(0, 0, -1, false, {
            ("# %s"):format(opts.title),
            "",
            "- STATE: OPEN",
            "- PRIORITY: 50",
            "",
            "",
        })
        local line_count = vim.api.nvim_buf_line_count(0)
        a.nvim_win_set_cursor(0, { line_count, 0 })
        vim.api.nvim_feedkeys("i", "nt", false)
    end)
end

function M.list_tasks(filter)
    vim.validate("filter", filter, { "nil", "function" })

    local database = M.get_database()
    if not database then
        return vim.notify("Tasks: no database found", vim.log.levels.ERROR)
    end

    local iter = vim.iter(vim.fs.dir(database)):map(function(x, _)
        local task_dir = vim.fs.joinpath(database, x)
        local task_file = vim.fs.joinpath(task_dir, "TASK.md")
        return {
            huid = x,
            task_dir = task_dir,
            task_file = task_file,
            title = M.get_task_title(task_file),
            priority = tonumber(M.get_task_priority(task_file)),
            state = M.get_task_state(task_file),
        }
    end)

    if type(filter) == "function" then
        iter:filter(filter)
    end

    local res = iter:totable()
    table.sort(res, function(x, y)
        return x.priority > y.priority
    end)
    return res
end

return M
