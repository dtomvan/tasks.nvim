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
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        { pkgs, lib, ... }:
        let
          inherit (lib.fileset) toSource unions;
        in
        {
          treefmt = {
            programs.nixfmt.enable = true;
            programs.stylua.enable = true;
          };
          packages.default = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
            luaRcContent =
              #lua
              ''
                require'tasks'.setup { add_commands = true }
                vim.keymap.set("n", "<leader>tg", require'tasks'.go_to)
                vim.keymap.set("n", "<leader>tn", require'tasks'.create_from_todo)
                vim.keymap.set("n", "<leader>tc", require'tasks'.new)
              '';
            wrapperArgs = [
              "--set"
              "NVIM_APPNAME"
              "nvim-tasks.nvim-dev"
            ];
            plugins = lib.singleton (
              pkgs.vimUtils.buildVimPlugin {
                name = "tasks";
                src = toSource {
                  root = ./.;
                  fileset = unions [
                    ./lua
                    ./README.md
                  ];
                };
              }
            );
          };
        };
    };
}
