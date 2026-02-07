local ok, _ = pcall(require, "telescope")
if not ok then
    return
end

local filters = require "tasks.filters"
local utils = require "tasks.utils"

local Task = require "tasks.task"

local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

local M = {}

local function make_picker(title, fn)
    return function(opts)
        opts = opts or {}
        return pickers
            .new(opts, {
                prompt_title = title,
                finder = finders.new_table {
                    results = fn(),
                    ---@param entry tasks.Task
                    entry_maker = function(entry)
                        return {
                            value = entry,
                            display = Task.pretty_print(entry),
                            ordinal = ("%03d %s %s %s"):format(
                                entry.priority,
                                entry.huid,
                                table.concat(entry.tags, " "),
                                entry.title
                            ),
                            path = entry.task_file,
                            lnum = 1, -- where the title goes, for quickfixlist purposes
                            text = "# " .. entry.title,
                        }
                    end,
                },
                sorter = conf.generic_sorter(opts),
                previewer = previewers.cat:new(),
            })
            :find()
    end
end

M.all_tasks = make_picker("All tasks", Task.list)
M.open_tasks = make_picker("Open tasks", function()
    return Task.list(filters.is_open)
end)
M.closed_tasks = make_picker("Closed tasks", function()
    return Task.list(filters.is_closed)
end)

function M.backlinks(opts)
    local task = Task.from_current_file()
    if task then
        Task.find_backlinks(task, function(backlinks)
            vim.schedule(function()
                pickers
                    .new(opts, {
                        prompt_title = ("Backlinks to %s"):format(task.huid),
                        finder = finders.new_table {
                            results = backlinks,
                            entry_maker = function(entry)
                                ---@cast entry tasks.Backlink
                                local display = utils.pretty_print_backlink(entry)
                                return {
                                    value = entry,
                                    display = display,
                                    ordinal = display,
                                    path = entry.filename,
                                    lnum = entry.lnum,
                                    text = entry.text,
                                }
                            end,
                        },
                        sorter = conf.generic_sorter(opts),
                        previewer = previewers.cat:new(),
                    })
                    :find()
            end)
        end)
    end
end

return M
