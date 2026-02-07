return require("telescope").register_extension {
    setup = function(ext_config, config)
        -- TODO: handle configs
        require "tasks".setup {}
    end,
    exports = {
        tasks = require("tasks.telescope").picker,
        backlinks = require("tasks.telescope").backlinks,
    },
}
