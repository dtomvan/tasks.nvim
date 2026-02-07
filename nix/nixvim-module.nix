{ self, inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.nixvim.default =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.nixvim.lua) toLua;

      cfg = config.plugins.tasks;
      settingsModule.options = {
        add_commands = lib.mkEnableOption "`Tasks` command for tasks.nvim";
      };
    in
    {
      options.plugins.tasks = {
        enable = lib.mkEnableOption "tasks.nvim plugin";
        package = lib.mkOption {
          description = "package for tasks.nvim";
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.plugin;
          type = lib.types.package;
        };
        settings = lib.mkOption {
          description = "settings to pass to `require'tasks'.setup { ... }`";
          type = lib.types.submodule settingsModule;
        };
        withTelescope = lib.mkEnableOption "telescope integration for tasks.nvim";
        withCmp = lib.mkEnableOption "nvim-cmp integration for tasks.nvim";
      };

      config = lib.mkIf cfg.enable {
        extraConfigLuaPost = ''
          require'tasks'.setup(${toLua cfg.settings})
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
