{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (lib.fileset) toSource unions;
    in
    {
      packages.plugin = pkgs.vimUtils.buildVimPlugin {
        name = "tasks";
        src = toSource {
          root = ../.;
          fileset = unions [
            ../after
            ../lua
            # bundle README.md for lazy.nvim
            ../README.md
          ];
        };
      };
    };
}
