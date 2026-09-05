# Project overview

This repository is the declarative NixOS configuration for the `workstation`
host.

## Working conventions

- Do not activate a new system generation with `nixos-rebuild switch` unless
  the user explicitly asks to change the running host.

## Validation

Format and evaluate changes from the repository root:

```sh
nix fmt
nix flake check
nix build .#nixosConfigurations.workstation.config.system.build.toplevel
```
