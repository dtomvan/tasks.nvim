-- templated from hrsh7th/cmp-buffer

local Task = require("tasks.task")

local defaults = {}

local source = {}

source.new = function()
    local self = setmetatable({}, { __index = source })
    return self
end

source._validate_options = function(_, params)
    local opts = vim.tbl_deep_extend("keep", params.option, defaults)
    vim.validate("opts", opts, "table")
    return opts
end

source.get_keyword_pattern = function(_, _)
    return "TASK%("
end

source.complete = function(self, params, callback)
    local _ = self:_validate_options(params)

    -- for now, let's assume it's cheap to list all available tasks

    local task_begin, task_end = string.find(params.context.cursor_before_line, "TASK(", 1, true)
    if not task_begin then
        return callback {
            items = {},
        }
    end

    local items = {}
    local tasks = Task.list()
    for _, task in ipairs(tasks) do
        table.insert(items, {
            label = task.huid,
            label_details = { description = task.task_file },
            kind = "file",
            documentation = io.open(task.task_file):read("*all"),
            textEdit = {
                newText = task.huid .. ")",
                range = {
                    start = { line = params.context.cursor.line, character = task_end },
                    ['end'] = { line = params.context.cursor.line, character = params.context.cursor.character },
                },
            },
            dup = 0,
        })
    end

    callback({
        items = items,
    })
end

return source
