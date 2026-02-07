return require("telescope").register_extension {
    setup = function(ext_config, config)
        -- TODO: handle configs
        require "tasks".setup {}
    end,
    exports = {
        tasks = require("tasks.telescope").open_tasks,
        open = require("tasks.telescope").open_tasks,
        closed = require("tasks.telescope").closed_tasks,
        all = require("tasks.telescope").all_tasks,
        backlinks = require("tasks.telescope").backlinks,
    },
}
