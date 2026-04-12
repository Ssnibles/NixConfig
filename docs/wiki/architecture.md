# Architecture

## Flake model

`flake.nix` is the entry point and wires:

- Stable system channel: `nixpkgs` (`nixos-25.11`)
- Unstable package set: `nixpkgs-unstable` (exposed as `pkgs.unstable`)
- Home Manager (`release-25.11`)
- Agenix (secrets)
- Disko (partitioning)
- Extra inputs (`zen-browser`, `awww`, `nix-minecraft`, local `switcheroo-src`)

## Outputs

- `nixosConfigurations`:
  - `desktop`, `laptop`
  - `desktop-test`, `laptop-test` (same hosts with `useDisko = false`)
- `homeConfigurations`:
  - `josh@desktop`
  - `josh@laptop`
- `diskoConfigurations`:
  - `desktop`
  - `laptop`

## Host builder

`lib/mkHost.nix` centralizes host wiring:

- Applies overlays (`zen-browser`, `awww`, `nix-minecraft`, `unstable`)
- Injects `hostProfile` flags into both NixOS and Home Manager modules
- Conditionally includes:
  - Disko modules when `useDisko = true`
  - NVIDIA module when `hasNvidia = true`

`hostProfile` fields:

- `hostName`
- `isLaptop`
- `isDesktop`
- `hasNvidia`
- `isVM`
- `useDisko`
- `user`

## Config flow

```text
flake.nix
  -> lib/mkHost.nix
    -> modules/nixos/common.nix + hosts/<name>
    -> users/josh/default.nix
      -> modules/home/*
```
