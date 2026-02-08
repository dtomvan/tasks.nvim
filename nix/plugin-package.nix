{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (lib.fileset) toSource unions;
    in
    {
      packages.plugin = pkgs.vimUtils.buildVimPlugin {
        pname = "tasks";
        version =
          self.sourceInfo.shortRev or "${self.sourceInfo.dirtyShortRev}-${self.sourceInfo.lastModifiedDate}";
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
