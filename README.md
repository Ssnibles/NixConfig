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
├── _options.nix         ← global options (e.g., username)
├── shell.nix            ← devShell
├── templates.nix        ← flake template exports
├── hosts/               ← per-machine configs
│   ├── desktop/
│   └── laptop/
├── features/
│   ├── layers/          ← composable system layers
│   │   ├── base.nix
│   │   ├── cli.nix
│   │   ├── communications.nix
│   │   ├── content-creation.nix
│   │   ├── cursors.nix
│   │   ├── development.nix
│   │   ├── fonts.nix
│   │   ├── gaming.nix
│   │   ├── media.nix
│   │   ├── pipewire.nix
│   │   ├── startup.nix
│   │   ├── user.nix
│   │   └── wallpapers.nix
│   ├── hyprland/        ← Hyprland variants
│   ├── mangowc/
│   ├── neovim.nix
│   ├── quickshell/
│   ├── vicinae/
│   ├── waybar/
│   └── zen-browser.nix
└── packages/            ← custom packages
    ├── boilerplate/
    ├── foot/
    ├── kitty/
    ├── noctalia/
    └── plsfail/
```

### Layers vs Features

- **Layers** (`modules/features/layers/`) are broad, reusable concern areas
  (base, CLI, communications, content creation, cursors, development, fonts,
  gaming, media, pipewire, startup, user, wallpapers). Mix and match per host.
- **Features** (`modules/features/`) are individual components (Hyprland,
  Mangowc, Neovim, Quickshell, Vicinae, Waybar, Zen Browser) with their own
  configuration.
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

Includes Rust tooling (rustc, cargo, rust-analyzer, clippy, rustfmt, bacon),
`sea-orm-cli`, `nixfmt`, `nil` (Nix LSP), `alejandra`, and the `boilerplate`
scaffolding tool.

## Rebuilding

```bash
sudo nixos-rebuild switch --flake ~/NixConfig#desktop
# or
sudo nixos-rebuild switch --flake ~/NixConfig#laptop
```
_Or use `nh`:_

```bash
nh os boot -H desktop
nh os boot -H laptop
```

## GitHub API Rate Limiting

Updating flake inputs hits GitHub's unauthenticated API (60 req/hr).
To avoid 403 errors, set the `GITHUB_TOKEN` environment variable in
your shell profile (e.g., `~/.zshenv`):

```bash
export GITHUB_TOKEN=ghp_xxxxx
```

Replace `ghp_xxxxx` with a [classic PAT](https://github.com/settings/tokens)
(no scopes needed for public repos). Nix's flake fetcher reads this
env var automatically — no config changes needed.
