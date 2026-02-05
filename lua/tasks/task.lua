local a = vim.api

local utils = require("tasks.utils")

---@class tasks.Task
---@field huid string HUID - Human Unique IDentifier, `date +'%Y%m%d-%H%M%S'`
---@field task_dir string Absolute path to the directory the task is in
---@field task_file string task_dir/TASK.md
---@field title string
---@field priority number 0-100
---@field state string Currently one of OPEN, CLOSED

local Task = {}

Task.DEFAULT_STATE = "OPEN"
Task.DEFAULT_PRIORITY = 50

function Task.make_template(title)
    return {
        ("# %s"):format(title),
        "",
        ("- STATE: %s"):format(Task.DEFAULT_STATE),
        ("- PRIORITY: %d"):format(Task.DEFAULT_PRIORITY),
        "",
        "",
    }
end

---@param filter function?
---@return tasks.Task[]
function Task.list(filter)
    vim.validate("filter", filter, { "nil", "function" })

    local database = utils.get_database()
    if not database then
        return vim.notify("Tasks: no database found", vim.log.levels.ERROR)
    end

    local iter = vim.iter(vim.fs.dir(database)):map(function(x, _)
        local task_dir = vim.fs.joinpath(database, x)
        local task_file = vim.fs.joinpath(task_dir, "TASK.md")

        local ok, task = pcall(Task.validate, Task.new({
            huid = x,
            task_dir = task_dir,
            task_file = task_file,
            -- "" is invalid, so error, but atleast type checking passes
            title = utils.get_task_title(task_file) or "",
            priority = tonumber(utils.get_task_priority(task_file)) or 50,
            state = utils.get_task_state(task_file),
        }))

        if not ok then
            vim.notify(("Tasks: invalid task %s: %s"):format(x, task), vim.log.levels.WARNING)
        end

        if ok then
            return task
        end
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

---@param task tasks.Task
---@return tasks.Task
function Task.new(task)
    return setmetatable(task, { __index = Task })
end

---@class tasks.TaskCreateOpts
---@field title string
---@field huid string?
---@field open boolean? default = true, whether to open the resulting file
---@field callback function?
---@param opts tasks.TaskCreateOpts
---@return tasks.Task
function Task.create(opts)
    vim.validate("opts.title", opts.title, "string")
    vim.validate("opts.huid", opts.huid, { "nil", "string" })
    vim.validate("opts.open", opts.open, { "nil", "boolean" })
    vim.validate("opts.callback", opts.callback, { "nil", "function" })

    local huid = opts.huid or utils.get_huid()
    local template = Task.make_template(opts.title)
    local task_file = utils.get_task_path_by_huid(huid, template)

    if opts.open ~= false then
        vim.cmd.split(task_file)
        vim.schedule(function()
            local line_count = vim.api.nvim_buf_line_count(0)
            a.nvim_win_set_cursor(0, { line_count, 0 })
            vim.api.nvim_feedkeys("i", "nt", false)
            if opts.callback then opts.callback(task_file) end
        end)
    end

    return Task.new {
        huid = huid,
        task_dir = vim.fs.parents(task_file)(),
        task_file = task_file,
        title = opts.title,
        priority = Task.DEFAULT_PRIORITY,
        state = Task.DEFAULT_STATE,
    }
end

---@return tasks.Task
function Task:validate()
    vim.validate("task", self, "table")
    vim.validate("task.huid", self.huid, function(v)
        if type(v) ~= "string" then
            return false
        end
        return string.match(v, "^%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d$") ~= nil
    end, "valid HUID")
    vim.validate("task.task_dir", self.task_dir, function(v)
        return vim.fn.isabsolutepath(v) == 1 and vim.fn.isdirectory(v) == 1
    end, "absolute path to existing directory")
    vim.validate("task.task_file", self.task_file, function(v)
        return vim.fn.isabsolutepath(v) == 1 and vim.uv.fs_stat(v) ~= nil and vim.fs.basename(v) == "TASK.md"
    end, "absolute path to existing file with name TASK.md")
    vim.validate("task.title", self.title, function(v)
        return type(v) == "string" and string.len(v) > 0
    end, "string with length > 0")
    vim.validate("task.priority", self.priority, function(v)
        if type(v) ~= "number" then
            return false
        end
        return v >= 0 and v <= 100
    end, "number between 0 and 100")
    vim.validate("task.state", self.state, function(v)
        if type(v) ~= "string" then
            return false
        end
        return string.match(v, "^%u+$") ~= nil
    end, "single word, all caps")

    return self
end

---Returns <PRIORITY> [HUID] TITLE
---Where PRIORITY is padded to 3 characters from the left with zeroes
---@return string
function Task:pretty_print()
    self:validate()
    return ("<%03d> [%s] %s"):format(self.priority, self.huid, self.title)
end

return Task
