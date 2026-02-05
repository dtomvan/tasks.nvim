local filters = require "tasks.filters"
local utils = require "tasks.utils"

local a = vim.api

local M = {}

function M.new()
    vim.ui.input({ prompt = "Enter title for task: ", default = "TODO" }, function(title)
        utils.create_task {
            title = title,
        }
    end)
end

function M.go_to()
    local line = utils.get_line()
    local huid = string.match(line, "TASK%((.*)%)")
    local ok, task_file = pcall(utils.get_task_by_huid, huid, false)
    if not ok then
        return vim.notify(("Tasks: no task with HUID %s"):format(huid), vim.log.levels.ERROR)
    end
    vim.cmd.split(task_file)
end

function M.create_from_todo()
    local line = utils.get_line()
    local prefix, suffix = string.match(line, "(.*)TODO:(.*)")
    if not prefix then
        return
    end -- silently do nothing is it doesn't make any sense
    ---@diagnostic disable-next-line: redefined-local
    local suffix = vim.trim(suffix)

    local huid = utils.get_huid()
    utils.set_line(prefix .. ("TASK(%s): "):format(huid) .. suffix)
    utils.create_task({ title = suffix })
end

function M.list()
    local tasks = utils.list_tasks(filters.is_open)
    local res = ""
    for _, task in ipairs(tasks) do
        res = res .. utils.pretty_print_task(task) .. "\n"
    end
    vim.print(res)
end

function M.qf_list()
    local cwd = vim.uv.cwd()
    local tasks = utils.list_tasks(filters.is_open)
    local res = {}
    for _, task in ipairs(tasks) do
        table.insert(res, {
            filename = vim.fs.relpath(cwd, task.task_file),
            lnum = 1,
            col = 1,
            text = "# " .. task.title,
        })
    end
    vim.fn.setqflist({}, "r", { title = ("Open tasks in %s"):format(cwd), items = res })
    vim.cmd.cope()
end

local function add_commands()
    for name, fn in pairs {
        TasksNew = M.new,
        TasksGoto = M.go_to,
        TasksCreateFromTODO = M.create_from_todo,
        TasksList = M.list,
        TasksQfList = M.qf_list,
    } do
        a.nvim_create_user_command(name, fn, { force = true })
    end
end

function M.setup(opts)
    if opts.add_commands or false then
        add_commands()
    end
end

return M
