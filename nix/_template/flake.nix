{
  description = "Flake for tasks.nvim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tasks = {
      url = "github:dtomvan/tasks.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.nixvim.flakeModules.default ];

      systems = import inputs.systems;

      nixvim = {
        packages.enable = true;
        checks.enable = true;
      };

      perSystem =
        { pkgs, system, ... }:
        {
          nixvimConfigurations.default = inputs.nixvim.lib.evalNixvim {
            inherit system;
            modules = [
              ./nixvim.nix
              {
                imports = [ inputs.tasks.modules.nixvim.default ];
                nixpkgs = { inherit pkgs; };
              }
            ];
          };
        };
    };
}
