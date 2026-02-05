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
