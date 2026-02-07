local filters = require "tasks.filters"
local utils = require "tasks.utils"

local Task = require "tasks.task"

local a = vim.api

local M = {}

function M.new()
    vim.ui.input({ prompt = "Enter title for task: ", default = "TODO" }, function(title)
        Task.create {
            title = title,
        }
    end)
end

function M.go_to()
    local line = utils.get_line()
    local huid = string.match(line, "TASK%((.*)%)")
    local ok, task_file = pcall(utils.get_task_path_by_huid, huid, nil)
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

    local current_path = vim.fn.expand("%:p")
    Task.create {
        title = suffix,
        huid = huid,
        callback = function(_)
            local root_dir = utils.get_root_dir()
            a.nvim_buf_set_lines(0, -2, -1, false, {
                vim.fs.joinpath("..", "..", vim.fs.relpath(root_dir, current_path)),
                "",
            })
        end,
    }
end

function M.list()
    local tasks = Task.list(filters.is_open)
    local res = ""
    for _, task in ipairs(tasks) do
        res = res .. Task.pretty_print(task) .. "\n"
    end
    vim.print(res)
end

function M.qf_list()
    local cwd = vim.uv.cwd()
    local tasks = Task.list(filters.is_open)
    local res = {}
    for _, task in ipairs(tasks) do
        table.insert(res, {
            filename = vim.fs.relpath(cwd, task.task_file),
            lnum = 1,
            col = 1,
            text = Task.pretty_print(task),
        })
    end
    vim.fn.setqflist({}, "r", { title = ("Open tasks in %s"):format(cwd), items = res })
    vim.cmd.cope()
end

function M.qf_backlinks()
    local task = Task.from_current_file()
    if task then
        Task.find_backlinks(task, function(backlinks)
            vim.schedule(function()
                vim.fn.setqflist({}, "r", { title = ("Backlinks to"):format(task.huid), items = backlinks })
                vim.cmd.cope()
            end)
        end)
    end
end

function M.backlinks()
    local task = Task.from_current_file()
    if task then
        Task.find_backlinks(task, function(backlinks)
            local res = ""
            for _, bl in ipairs(backlinks) do
                res = res .. utils.pretty_print_backlink(bl) .. "\n"
            end
            vim.print(res)
        end)
    end
end

M.COMMANDS = {
    new = M.new,
    ["goto"] = M.go_to,
    ["create-from-todo"] = M.create_from_todo,
    list = M.list,
    ["qf-list"] = M.qf_list,
    backlinks = M.backlinks,
    ["qf-backlinks"] = M.qf_backlinks,
}

M.COMMAND_LIST = {}

for n, _ in pairs(M.COMMANDS) do
    table.insert(M.COMMAND_LIST, n)
end

function M.interactive(e)
    M.COMMANDS[e.fargs[1]](unpack(vim.list_slice(e.fargs, 2)))
end

local function add_commands()
    a.nvim_create_user_command("Tasks", M.interactive, {
        nargs = "+",
        force = true,
        complete = function(lead)
            return vim.iter(M.COMMAND_LIST)
                :filter(function(c)
                    return vim.startswith(c, lead)
                end)
                :totable()
        end,
    })
end

function M.setup(opts)
    if opts.add_commands or false then
        add_commands()
    end
end

return M
