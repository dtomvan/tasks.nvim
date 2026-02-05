{
  perSystem =
    { pkgs, self', ... }:
    {
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
}
