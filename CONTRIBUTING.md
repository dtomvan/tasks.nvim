# Contributing

When contributing, you have to adhere to the [MIT license](https://opensource.org/license/mit) as well as the [DCO](https://developercertificate.org/).

## Prerequisites

Just [Nix](https://nixos.org/download). [Neovim](https://neovim.org) recommended.

Also useful:
- [lua-language-server](https://github.com/LuaLS/lua-language-server) or [VSCode Lua extension](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
- [nixd](https://github.com/nix-community/nixd) or [VSCode nix-ide extension](https://github.com/nix-community/nixd)

## Issues

Don't submit any issues via the "Issues" tab in GitHub, rather, send a PR,
where a `tasks/<HUID>/TASK.md` file is being proposed. Refer to the format of
other existing tasks or use `TaskNew` from this plugin.

## Testing

There's an ephemeral NVim installation available in the Nix flake.

Run `nix run` to test out your changes manually.

Run `nix flake check` to just check that the plugin loads and some rudimentary integration tests pass.

## Formatting

Run `nix fmt`. The project is formatted with [nixfmt](https://github.com/nixos/nixfmt) and [stylua](https://github.com/JohnnyMorganz/StyLua).
