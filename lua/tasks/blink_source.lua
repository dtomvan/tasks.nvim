local Task = require("tasks.task")

--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

function source.new(opts)
    local self = setmetatable({}, { __index = source })
    self.opts = opts
    return self
end

function source:get_trigger_characters()
    return { "(" }
end

---@param ctx blink.cmp.Context
function source:get_completions(ctx, callback)
    local line_before_cursor = ctx.line:sub(1, ctx.cursor[2])
    local task_begin, task_end = string.find(line_before_cursor, "TASK(", 1, true)
    if not task_begin then
        return callback {
            items = {},
            is_incomplete_backward = true,
            is_incomplete_forward = true,
        }
    end

    local items = {}
    local tasks = Task.list()
    for _, task in ipairs(tasks) do
        --- @type lsp.CompletionItem
        local item = {
            label = task.huid,
            label_details = { description = task.task_file },
            kind = require("blink.cmp.types").CompletionItemKind.Text,

            textEdit = {
                newText = task.huid .. ")",
                range = {
                    start = { line = ctx.cursor[1] - 1, character = task_end },
                    ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
                },
            },

            insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
        }
        table.insert(items, item)
    end

    callback({
        items = items,
        is_incomplete_backward = false,
        is_incomplete_forward = false,
    })
end

function source:resolve(item, callback)
    item = vim.deepcopy(item)

    item.documentation = {
        kind = "markdown",
        value = io.open(item.label_details.description):read("*all"),
    }

    callback(item)
end

return source
