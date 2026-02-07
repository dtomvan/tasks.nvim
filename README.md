# tasks.nvim

@Tsoding's take on in-tree issue reporting/task management.

Inspired by this Tsoding Daily video: https://youtu.be/QH6KOEVnSZA

Note that the MVP (matching Tsoding's functionality) was implemented in the
initial commit ([41ed9234428c1ce5753d5a2f981d7285babd8554](https://github.com/dtomvan/tasks.nvim/commit/41ed9234428c1ce5753d5a2f981d7285babd8554)) and
this codebase got more and more complex as I went down the rabbit hole.

## Features
- Create tasks from template
- Create tasks from `TODO`s in the codebase
- List (open) tasks
- Open tasks in a [quickfix](https://neovim.io/doc/user/quickfix.html)list.
- Jump to mentions of tasks
- Find backlinks (yes, also between tasks)
- [Telescope](https://github.com/nvim-telescope/telescope.nvim) integration
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) integration

## Usage

Required for backlink search: use a Git repository. Currently it's hardcoded to
use `git grep` to search through all tracked files in the codebase.

<details>
<summary>Built-in nvim package management</summary>
OPTIONAL: install telescope and nvim-cmp for a better experience

```lua
require'tasks'.setup { add_commands = true }
vim.keymap.set("n", "<leader>tg", require'tasks'.go_to)
vim.keymap.set("n", "<leader>tn", require'tasks'.create_from_todo)
vim.keymap.set("n", "<leader>tc", require'tasks'.new)
vim.keymap.set("n", "<leader>tl", require'tasks'.list)
vim.keymap.set("n", "<leader>tq", require'tasks'.qf_list)
vim.keymap.set("n", "<leader>tb", require'tasks'.qf_backlinks)

-- OPTIONAL: telescope finder with `:Telescope tasks`
require'telescope'.setup { extensions = { tasks = {} } }
require('telescope').load_extension('tasks')
vim.keymap.set("n", "<leader>to", "<cmd>Telescope tasks<cr>")
vim.keymap.set("n", "<leader>tb", "<cmd>Telescope tasks backlinks<cr>")

-- OPTIONAL: cmp source
require'cmp'.setup { sources = { { name = 'tasks' } } }
```
</details>

<details>
<summary>With Lazy.nvim</summary>

```lua
return {
    {
        "dtomvan/tasks.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        opts = {
            add_commands = true,
        },
        keys = {
            { "<leader>tg", "<cmd>Tasks goto<cr>", desc = "Go to task" },
            { "<leader>tn", "<cmd>Tasks create-from-todo<cr>", desc = "Create task from TODO comment" },
            { "<leader>tc", "<cmd>Tasks new<cr>", desc = "Create task from scratch" },
            { "<leader>tl", "<cmd>Tasks list<cr>", desc = "List open tasks" },
            { "<leader>tq", "<cmd>Tasks qf-list<cr>", desc = "Set quickfix list to open tasks" },
            { "<leader>to", function() require'tasks.telescope'.open_tasks() end, desc = "Use telescope to search through open tasks" },
            { "<leader>tb", function() require'tasks.telescope'.backlinks() end, desc = "Use telescope to search through open tasks" },
        },
    },
    { "hrsh7th/nvim-cmp", opts = { sources = { { name = "tasks" } }, dependencies = { "dtomvan/tasks.nvim" } } },
}
```

</details>

<details>
<summary>With nixvim</summary>
Make sure to pass `inputs` via `specialArgs` in your home-manager
configuration, or otherwise (e.g. flake-parts) find a way to import the module
in your nixvim configuration.

For a full template for standalone nixvim, run:
```bash
nix flake init -t github:dtomvan/tasks.nvim
```

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
    imports = [ inputs.tasks.modules.nixvim.default ];
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

</details>
