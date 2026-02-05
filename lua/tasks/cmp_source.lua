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

    local input = string.sub(params.context.cursor_before_line, params.offset)
    local items = {}
    -- TODO: factor out list_huids
    local tasks = Task.list()
    for _, task in ipairs(tasks) do
        if vim.startswith(task.huid, input) and task.huid ~= input then
            table.insert(items, {
                label = task.huid,
                label_details = { description = task.task_file },
                kind = "file",
                documentation = io.open(task.task_file):read("*all"),
                insert_text = task.huid .. ")",
                dup = 0,
            })
        end
    end

    callback({
        items = items,
    })
end

return source
