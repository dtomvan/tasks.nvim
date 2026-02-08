{ inputs, self, ... }:
{
  flake.githubActions = inputs.nix-github-actions.lib.mkGithubMatrix {
    checks = inputs.nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system: {
      inherit (self.checks.${system}) treefmt integration;
    });
  };
}
