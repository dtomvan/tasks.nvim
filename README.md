# tasks.nvim

@Tsoding's take on in-tree issue reporting/task management.

## Usage

### Bare nvim package management
OPTIONAL: install telescope and nvim-cmp for a better experience

```lua
require'tasks'.setup { add_commands = true }
vim.keymap.set("n", "<leader>tg", require'tasks'.go_to)
vim.keymap.set("n", "<leader>tn", require'tasks'.create_from_todo)
vim.keymap.set("n", "<leader>tc", require'tasks'.new)

-- OPTIONAL: telescope finder with `:Telescope tasks`
require'telescope'.setup { extensions = { tasks = {} } }
require('telescope').load_extension('tasks')
vim.keymap.set("n", "<leader>to", "<cmd>Telescope tasks<cr>")

-- OPTIONAL: cmp source
require'cmp'.setup { sources = { { name = 'tasks' } } }
```

### With Lazy.nvim
```lua
return {
    {
        "dtomvan/tasks.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        opts = {
            add_commands = true,
        },
        keys = {
            { "<leader>tg", "<cmd>TasksGoto<cr>", desc = "Go to task" },
            { "<leader>tn", "<cmd>TasksCreateFromTODO<cr>", desc = "Create task from TODO comment" },
            { "<leader>tc", "<cmd>TasksNew<cr>", desc = "Create task from scratch" },
            { "<leader>to", function() require'tasks.telescope'.picker() end, desc = "Use telescope to search through open tasks" },
        },
    },
    { "hrsh7th/nvim-cmp", opts = { sources = { { name = "tasks" } }, dependencies = { "dtomvan/tasks.nvim" } } },
}
```

### With nixvim
Make sure to pass `inputs` via `specialArgs` in your home-manager
configuration, or otherwise (e.g. flake-parts) find a way to import the module
in your nixvim configuration.

```nix
# flake.nix
{
  inputs = {
    inputs.tasks.url = "github:dtomvan/tasks.nvim";
  };
}

# home.nix
{ inputs, ... }:
{
  programs.nixvim = {
    imports = [ inputs.tasks.modules.nixvim ];
    plugins.tasks = {
      enable = true;
      withTelescope = true;
      withCmp = true;
      settings = {
        add_commands = true;
      };
    };
  };
}
```
