{
  plugins.tasks = {
    enable = true;
    withTelescope = true;
    withBlink = true;
    settings = {
      add_commands = true;
    };
  };

  keymaps = [
    {
      key = "<leader>tg";
      action = "<cmd>Tasks goto<cr>";
    }
    {
      key = "<leader>tn";
      action = "<cmd>Tasks create-from-todo<cr>";
    }
    {
      key = "<leader>tc";
      action = "<cmd>Tasks new<cr>";
    }
    {
      key = "<leader>tl";
      action = "<cmd>Tasks list<cr>";
    }
    {
      key = "<leader>tq";
      action = "<cmd>Tasks qf-list<cr>";
    }
    {
      key = "<leader>to";
      action = "<cmd>Telescope tasks open<cr>";
    }
    {
      key = "<leader>tb";
      action = "<cmd>Telescope tasks backlinks<cr>";
    }
  ];
}
