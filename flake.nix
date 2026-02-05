{
  description = "Flake for tasks.nvim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        systems = import inputs.systems;

        imports = [
          inputs.treefmt-nix.flakeModule
          inputs.flake-parts.flakeModules.modules
        ];

        perSystem =
          {
            pkgs,
            lib,
            self',
            ...
          }:
          let
            inherit (lib.fileset) toSource unions;
          in
          {
            treefmt = {
              programs.nixfmt.enable = true;
              programs.stylua = {
                enable = true;
                settings = {
                  indent_type = "Spaces";
                  # I like to be free-form with my parens, I don't think it hurts
                  # readability much
                  call_parentheses = "Input";
                };
              };
            };

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
              plugins = [
                # optional dependencies
                pkgs.vimPlugins.telescope-nvim
                pkgs.vimPlugins.nvim-cmp
                self'.packages.plugin
              ];
            };

            packages.plugin = pkgs.vimUtils.buildVimPlugin {
              name = "tasks";
              src = toSource {
                root = ./.;
                fileset = unions [
                  ./after
                  ./lua
                  ./README.md
                ];
              };
            };

            checks.loadCheck =
              pkgs.runCommand "load-tasks.nvim"
                {
                  nativeBuildInputs = with pkgs; [
                    coreutils
                    self'.packages.default
                  ];
                }
                ''
                  export HOME=`mktemp -d`
                  nvim +'norm iHello, World!' +"w $out" +q
                '';
          };

        flake.modules.nixvim.default =
          {
            pkgs,
            lib,
            config,
            ...
          }:
          let
            cfg = config.plugins.tasks;
          in
          {
            options.plugins.tasks = {
              enable = lib.mkEnableOption "tasks.nvim plugin";
              package = lib.mkOption {
                description = "package for tasks.nvim";
                default = self.packages.${pkgs.stdenv.hostPlatform.system}.plugin;
                type = lib.types.package;
              };
              # TODO: add settings, how to serialize to lua?
              withTelescope = lib.mkEnableOption "telescope integration for tasks.nvim";
              withCmp = lib.mkEnableOption "nvim-cmp integration for tasks.nvim";
            };
            config = lib.mkIf cfg.enable {
              extraConfigLuaPost = ''
                require'tasks'.setup { add_commands = true }
              '';

              extraPlugins = lib.singleton cfg.package;

              plugins.telescope = lib.mkIf cfg.withTelescope {
                enable = true;
                enabledExtensions = lib.singleton "tasks";
              };

              plugins.cmp = lib.mkIf cfg.withCmp {
                enable = true;
                settings.sources = lib.singleton { name = "tasks"; };
              };
            };
          };
      }
    );
}
