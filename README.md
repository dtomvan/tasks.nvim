# tasks.nvim

@Tsoding's take on in-tree issue reporting/task management.

## Usage

### Bare nvim package management
```lua
-- Adds commands `TasksGoto` and `TasksCreateFromTODO`
require'tasks'.setup { add_commands = true }
vim.keymap.set("n", "<leader>tg", require'tasks'.go_to)
vim.keymap.set("n", "<leader>tn", require'tasks'.create_from_todo)
vim.keymap.set("n", "<leader>tc", require'tasks'.new)
```

### With Lazy.nvim
```lua
return {
    "dtomvan/tasks.nvim",
    opts = {
        add_commands = true,
    },
    keys = {
        { "<leader>tg", "<cmd>TasksGoto<cr>", desc = "Go to task" },
        { "<leader>tn", "<cmd>TasksCreateFromTODO<cr>", desc = "Create task from TODO comment" },
        { "<leader>tc", "<cmd>TasksNew<cr>", desc = "Create task from scratch" },
    },
}
```
