local ok, _ = pcall(require, "telescope")
if not ok then
    return
end

local utils = require "tasks.utils"

local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

local M = {}

function M.picker(opts)
    opts = opts or {}
    return pickers
        .new(opts, {
            prompt_title = "tasks",
            finder = finders.new_table {
                results = utils.list_tasks(function(task)
                    -- allow for more states than open and closed, but only make closed the one that hides
                    return task.state ~= "CLOSED"
                end),
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = ("<%03d> [%s] %s"):format(entry.priority, entry.huid, entry.title),
                        ordinal = ("%03d %s %s"):format(entry.priority, entry.huid, entry.title),
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

return M
