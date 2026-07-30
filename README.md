# NixConfig

A [dendritic](https://github.com/mightyiam/dendritic) NixOS configuration using
`flake-parts` and `import-tree`. The filesystem tree *is* the module tree —
every `.nix` file under `modules/` is auto-discovered.

Pins `nixos-26.05` (stable) alongside `nixos-unstable` for select packages.

## Quick Install

```bash
# Desktop
sudo bash install.sh --host desktop --disk /dev/sda

# Laptop
sudo bash install.sh --host laptop --disk /dev/nvme0n1
```

The installer partitions the disk (UEFI GPT), clones this repo, generates
hardware config, and runs `nixos-install`. Use `--dry-run` to preview.

## Project Structure

```
flake.nix              ← entry point: flake-parts + import-tree
install.sh             ← bootstrap installer
modules/
├── parts.nix          ← supported systems
├── _options.nix       ← global options (username, wallpaper)
├── shell.nix          ← devShell (Rust, Nix tooling, boilerplate)
├── templates.nix      ← flake template exports
├── hosts/             ← per-machine configs
│   ├── desktop/       ← GDM + Hyprland-noctalia, systemd-boot
│   └── laptop/        ← Ly + MangoWC/Niri, Limine, swapfile
├── features/
│   ├── layers/        ← composable concern areas
│   │   ├── base.nix           nix settings, timezone, locale, networking
│   │   ├── cli.nix            ZSH, Fish, Starship, zoxide, git
│   │   ├── communications.nix Vesktop, Mumble
│   │   ├── content-creation.nix Audacity, GIMP, ffmpeg
│   │   ├── cursors.nix       Bibata cursors
│   │   ├── development.nix   Neovim, opencode, nodejs, cargo, direnv, yazi, zellij
│   │   ├── fonts.nix         JetBrainsMono, MartianMono, Noto, etc.
│   │   ├── gaming.nix        Steam + Millennium, gamescope, mangohud
│   │   ├── media.nix         Spotify, Zathura
│   │   ├── pipewire.nix      PipeWire + wireplumber
│   │   ├── startup.nix       vicinae-server user service
│   │   ├── user.nix          user account + hjem
│   │   └── wallpapers.nix    wallpaper symlinks via hjem
│   ├── hyprland/      ← Hyprland compositor variants
│   │   ├── hyprland-noctalia/  desktop (noctalia shell)
│   │   └── hyprland-waybar/    laptop variant
│   ├── mangowc/       ← MangoWC compositor (laptop)
│   ├── niri/          ← Niri compositor (laptop)
│   │   └── niri-quickshell/    QML bar for Niri
│   ├── quickshell/    ← QML shell (standalone, for MangoWC)
│   ├── vicinae/       ← app launcher (all compositors)
│   ├── neovim.nix     ← nvf-based Neovim with LSP/DAP/debuggers
│   ├── nvim-src/      ← custom Lua config (lazy-loaded plugins)
│   ├── zen-browser.nix
│   ├── qutebrowser.nix
│   └── podman-vm.nix  ← distrobox, Vivado VM
├── packages/          ← custom packages
│   ├── boilerplate/   ← scaffolding tool
│   ├── foot/          ← foot terminal + NixOS module
│   ├── kitty/         ← kitty terminal + NixOS module
│   ├── noctalia/      ← noctalia-shell wrapper
│   └── plsfail/       ← "run until failure" utility
└── themes/            ← theme system
    ├── default.nix    ← theme options (colors, fonts)
    └── palette.nix    ← available schemes (catppuccin, gruvbox, rose-pine, vague, ...)
```

## Hosts

| Host    | Compositor(s)     | Display Manager | Bootloader | GPU     |
| ------- | ----------------- | --------------- | ---------- | ------- |
| desktop | Hyprland-noctalia | GDM             | systemd-boot | AMD |
| laptop  | MangoWC + Niri    | Ly              | Limine     | AMD |

Both use the same layered modules — each host imports a subset of layers
and features via its `configuration.nix`.

## Development Shell

```bash
nix develop
# or with nix-direnv: direnv allow
```

Includes Rust tooling (rustc, cargo, rust-analyzer, clippy, rustfmt, bacon),
`sea-orm-cli`, `nixfmt`, `nil` (Nix LSP), `alejandra`, `fish`, and the
`boilerplate` scaffolding tool.

## Common Tasks

```bash
# Rebuild desktop
sudo nixos-rebuild switch --flake ~/NixConfig#desktop

# Rebuild laptop
sudo nixos-rebuild switch --flake ~/NixConfig#laptop

# Or using nh
nh os boot -H desktop
nh os boot -H laptop

# Update flake inputs
nix flake update
```

## Scaffolding

```bash
boilerplate host my-new-host     # new machine
boilerplate layer my-layer       # new layer (modules/features/layers/)
boilerplate feature my-thing     # new feature (modules/features/)
boilerplate package my-tool      # new package (modules/packages/)
```

## Template

```bash
nix flake init -t github:Ssnibles/NixConfig#generic
```

Scaffolds a minimal dendritic flake with `flake-parts`, `import-tree`,
and `nixpkgs` pinned to `nixos-26.05`.

## GitHub API Rate Limiting

Updating flake inputs hits GitHub's unauthenticated API (60 req/hr).
To avoid 403 errors, set `GITHUB_TOKEN` in your shell profile:

```bash
export GITHUB_TOKEN=ghp_xxxxx
```

Generate a [classic PAT](https://github.com/settings/tokens) — no scopes
needed for public repos. Nix's flake fetcher reads this automatically.
