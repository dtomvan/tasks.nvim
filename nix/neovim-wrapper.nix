# `nix run .` to test out the plugin in a seperate neovim config
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.wrapper = pkgs.callPackage (
        {
          wrapNeovimUnstable,
          neovim-unwrapped,
          vimPlugins,
          withCmp ? false,
          withBlink ? true,
        }:
        wrapNeovimUnstable neovim-unwrapped {
          luaRcContent =
            #lua
            ''
              require'telescope'.setup { extensions = { tasks = {} } }
              require('telescope').load_extension('tasks')
              require'tasks'.setup { add_commands = true }
              ${lib.optionalString withCmp ''
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
                }''}

              ${lib.optionalString withBlink ''
                require'blink.cmp'.setup {
                  sources = {
                    default = { 'tasks' },
                    providers = {
                      tasks = {
                        name = 'Tasks',
                        module = 'tasks.blink_source',
                      }
                    }
                  }
                }''}

              vim.keymap.set("n", "<leader>tg", require'tasks'.go_to)
              vim.keymap.set("n", "<leader>tn", require'tasks'.create_from_todo)
              vim.keymap.set("n", "<leader>tc", require'tasks'.new)
              vim.keymap.set("n", "<leader>tl", require'tasks'.list)
              vim.keymap.set("n", "<leader>tq", require'tasks'.qf_list)
              vim.keymap.set("n", "<leader>to", "<cmd>Telescope tasks<cr>")
              vim.keymap.set("n", "<leader>tb", "<cmd>Telescope tasks backlinks<cr>")
            '';
          wrapperArgs = [
            "--set"
            "NVIM_APPNAME"
            "nvim-tasks.nvim-dev"
          ];
          plugins =
            with vimPlugins;
            [
              self'.packages.plugin
              # optional dependencies
              telescope-nvim
            ]
            ++ lib.optionals withCmp [ nvim-cmp ]
            ++ lib.optionals withBlink [ blink-cmp ];
        }
      ) { };

      packages.default = self'.packages.wrapper.overrideAttrs { dontFixup = true; };

      packages.wrapperWithCmp =
        (self'.packages.wrapper.override {
          withCmp = true;
          withBlink = false;
        }).overrideAttrs
          { dontFixup = true; };
    };
}
