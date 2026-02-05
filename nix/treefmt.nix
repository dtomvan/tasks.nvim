{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem.treefmt.programs = {
    nixfmt.enable = true;
    stylua = {
      enable = true;
      settings = {
        indent_type = "Spaces";
        # I like to be free-form with my parens, I don't think it hurts
        # readability much
        call_parentheses = "Input";
      };
    };
  };
}
