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
    let
      inherit (builtins)
        readDir
        attrNames
        concatMap
        ;

      inherit (inputs.nixpkgs) lib;

      listFilesRecursiveCond =
        dir: condition:
        let
          internalFunc =
            folder:
            let
              contents = readDir folder;
            in
            concatMap (
              filename:
              let
                subpath = folder + "/${filename}";
                type = contents.${filename};
              in
              if condition { inherit filename type; } then
                if type == "regular" then
                  [ subpath ]
                else if type == "directory" then
                  internalFunc subpath
                else
                  [ ]
              else
                [ ]
            ) (attrNames contents);
        in
        internalFunc dir;

      isNixFile =
        { filename, type }:
        (lib.hasSuffix ".nix" filename || type == "directory") && !lib.hasPrefix "_" filename;
      import-tree = dir: (listFilesRecursiveCond dir isNixFile);
    in
    flake-parts.lib.mkFlake { inherit inputs; } { imports = import-tree ./nix; };
}
