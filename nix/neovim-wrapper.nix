# `nix run .` to test out the plugin in a seperate neovim config
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.default = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
        luaRcContent =
          #lua
          ''
            require'telescope'.setup { extensions = { tasks = {} } }
            require('telescope').load_extension('tasks')
            require'tasks'.setup { add_commands = true }
            local cmp = require'cmp'
            cmp.setup {
              sources = { { name = 'tasks' } },
              mapping = cmp.mapping.preset.insert({
                  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                  ['<C-f>'] = cmp.mapping.scroll_docs(4),
                  ['<C-Space>'] = cmp.mapping.complete(),
                  ['<C-e>'] = cmp.mapping.abort(),
                  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
              }),
              snippet = {
                expand = function(args)
                  vim.snippet.expand(args.body)
                end,
              },
            }

            vim.keymap.set("n", "<leader>tg", require'tasks'.go_to)
            vim.keymap.set("n", "<leader>tn", require'tasks'.create_from_todo)
            vim.keymap.set("n", "<leader>tc", require'tasks'.new)
            vim.keymap.set("n", "<leader>to", "<cmd>Telescope tasks<cr>")
          '';
        wrapperArgs = [
          "--set"
          "NVIM_APPNAME"
          "nvim-tasks.nvim-dev"
        ];
        plugins = with pkgs.vimPlugins; [
          # optional dependencies
          telescope-nvim
          nvim-cmp
          self'.packages.plugin
        ];
      };
    };
}
