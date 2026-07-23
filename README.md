# NixConfig

A [dendritic](https://github.com/vic/import-tree) NixOS configuration using
`flake-parts` and `import-tree`. The filesystem tree *is* the module tree —
every `.nix` file under `modules/` is automatically discovered and imported.

## Quick Install

```bash
# Desktop
bash <(curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/dendritic/install.sh) --host desktop --disk /dev/sda

# Laptop
bash <(curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/dendritic/install.sh) --host laptop --disk /dev/nvme0n1
```

The installer partitions the disk (UEFI GPT), clones this repo, generates
hardware config, and runs `nixos-install`. Use `--dry-run` to preview without
making changes.

## Project Structure

```
flake.nix                ← entry point: flake-parts + import-tree
install.sh               ← bootstrap installer
modules/
├── parts.nix            ← supported systems
├── options.nix          ← global options (e.g., username)
├── shell.nix            ← devShell
├── templates.nix        ← flake template exports
├── hosts/               ← per-machine configs
│   ├── desktop/
│   └── laptop/
├── features/
│   ├── layers/          ← composable system layers
│   │   ├── base.nix
│   │   ├── development.nix
│   │   ├── fonts.nix
│   │   ├── gaming.nix
│   │   ├── pipewire.nix
│   │   └── ...
│   ├── hyprland/        ← Hyprland variants
│   ├── quickshell/
│   └── librewolf.nix
└── packages/            ← custom packages
    ├── boilerplate/
    ├── kitty/
    ├── foot/
    ├── noctalia/
    └── plsfail/
```

### Layers vs Features

- **Layers** (`modules/features/layers/`) are broad, reusable concern areas
  (base system, development tools, fonts, gaming). Mix and match per host.
- **Features** (`modules/features/`) are individual components (Hyprland,
  Quickshell, LibreWolf) with their own configuration.
- **Hosts** (`modules/hosts/`) assemble layers and features into a complete
  system configuration.

## Adding a New Host

```bash
# Using the boilerplate tool (available in devShell):
boilerplate host my-new-host

# Or manually:
mkdir -p modules/hosts/my-new-host
# Create default.nix + configuration.nix + _hardware-generated.nix
```

Then add it to your flake outputs and run:
```bash
sudo nixos-install --flake .#my-new-host
```

## Adding a New Package

```bash
boilerplate package my-tool
# Creates modules/packages/my-tool.nix
```

Or with multiple files:
```bash
boilerplate package my-tool --multifile
# Creates modules/packages/my-tool/default.nix
```

## Adding a New Layer or Feature

```bash
boilerplate layer my-layer    # modules/features/layers/my-layer.nix
boilerplate feature my-thing  # modules/features/my-thing.nix
```

## Templates

This flake exports a template for scaffolding new dendritic flakes:

```bash
nix flake init -t github:Ssnibles/NixConfig#generic
```

This creates a minimal `flake.nix` ready for `flake-parts` + `import-tree`,
with `nixpkgs` pinned to nixos-26.05. Run `nix build .#hello` to verify.

## Development Shell

```bash
nix develop
# or via nix-direnv: direnv allow
```

Includes `nixfmt`, `nil` (Nix language server), `alejandra`, and the
`boilerplate` scaffolding tool.

## Rebuilding

```bash
sudo nixos-rebuild switch --flake ~/NixConfig#desktop
# or
sudo nixos-rebuild switch --flake ~/NixConfig#laptop
```
