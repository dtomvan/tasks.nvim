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

function M.get_task_by_huid(huid, create)
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

function M.create_task(opts)
    vim.validate("opts.title", opts.title, "string")
    vim.validate("opts.huid", opts.huid, { "nil", "string" })

    local task_file = M.get_task_by_huid(opts.huid or M.get_huid(), true)
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

return M
