{
  flake.templates.default = {
    path = ./_template;
    description = "Using nixvim standalone with tasks.nvim";
    welcomeText = ''
      # First steps
      1. git init; git add \*\*/\*.nix; git commit -m "initial commit"
      2. nix profile install .
    '';
  };
}
