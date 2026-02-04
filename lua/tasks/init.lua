local a = vim.api

local M = {}

local function get_line()
    local row, _ = unpack(a.nvim_win_get_cursor(0))
    return a.nvim_buf_get_lines(0, row - 1, row, true)[1]
end

local function set_line(line)
    local row, _ = unpack(a.nvim_win_get_cursor(0))
    return a.nvim_buf_set_lines(0, row - 1, row, true, { line })
end

local function get_huid()
    return os.date("%Y%m%d-%H%M%S")
end

local function get_database()
    local root_dir = vim.fs.root(0, ".git")
    if root_dir then return vim.fs.joinpath(root_dir, "tasks") end
end

local function get_task_by_huid(huid, create)
    local db = get_database()
    if not db then return vim.notify("Tasks: no database found", vim.log.levels.ERROR) end

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

local function create_task(opts)
    local task_file = get_task_by_huid(opts.huid or get_huid(), true)
    vim.cmd.split(task_file)
    vim.schedule(function()
        a.nvim_buf_set_lines(0, 0, -1, false, {
            ("# %s"):format(opts.title),
            "",
            "- STATE: OPEN",
            "- priority: 50",
            "",
            "",
        })
        local line_count = vim.api.nvim_buf_line_count(0)
        a.nvim_win_set_cursor(0, { line_count, 0 })
        vim.api.nvim_feedkeys("i", "nt", false)
    end)
end

function M.new()
    vim.ui.input({ prompt = "Enter title for task: ", default = "TODO" }, function(title)
        create_task {
            title = title,
        }
    end)
end

function M.go_to()
    local line = get_line()
    local huid = string.match(line, "TASK%((.*)%)")
    local ok, task_file = pcall(get_task_by_huid, huid, false)
    if not ok then return vim.notify(("Tasks: no task with HUID %s"):format(huid), vim.log.levels.ERROR) end
    vim.cmd.split(task_file)
end

function M.create_from_todo()
    local line = get_line()
    local prefix, suffix = string.match(line, "(.*)TODO:(.*)")
    if not prefix then return end -- silently do nothing is it doesn't make any sense
    ---@diagnostic disable-next-line: redefined-local
    local suffix = vim.trim(suffix)

    local huid = get_huid()
    set_line(prefix .. ("TASK(%s): "):format(huid) .. suffix)
    create_task({ title = suffix })
end

local function add_commands()
    for name, fn in pairs {
        TasksNew = M.new,
        TasksGoto = M.go_to,
        TasksCreateFromTODO = M.create_from_todo,
    } do
        a.nvim_create_user_command(name, fn, { force = true, })
    end
end

function M.setup(opts)
    if opts.add_commands or false then
        add_commands()
    end
end

return M
