# NixConfig

Personal multi-host NixOS + Home Manager flake for `desktop` and `laptop`, with Hyprland, Neovim, Fish, and Agenix-managed secrets.

## Quick start

### Fresh install (from NixOS ISO)

```bash
sudo bash <(curl -L https://raw.githubusercontent.com/Ssnibles/NixConfig/main/install.sh) \
  --host desktop --disk /dev/nvme0n1
```

Use `--host laptop` for laptop installs.  
`install.sh` will wipe the selected disk.

### Daily workflow

```bash
cd ~/NixConfig
bash ./check.sh
```

Then apply changes with one of:

| Scope | Command |
|---|---|
| Full system (kernel, drivers, services, boot, etc.) | `nh os switch` |
| Home Manager only (Hyprland, Waybar, shell, Neovim, etc.) | `nh home switch` |
| Home Manager with explicit target | `nh home switch -c josh@desktop` |

Fish abbreviations in this repo:

| Abbr | Expands to |
|---|---|
| `rebuild` | `nh os switch` |
| `hm` | `nh home switch` |
| `update` | `nh os switch --update` |
| `clean` | `nh clean all` |

### Stylix theme switcher

This repo now includes a declarative Stylix switcher for supported programs.

```bash
stylix-switch --list
stylix-switch catppuccin-mocha
```

Themes are defined in `lib/stylix/themes.nix`, and the active theme key lives in `lib/stylix/current-theme.nix`.

## Spotify + Agenix setup (what goes in each `.age` file)

This config expects:

- `secrets/spotify-id.age` → Spotify **Client ID**
- `secrets/spotify-secret.age` → Spotify **Client Secret**

Those values come from Spotify Developer Dashboard, not from `age-keygen`.

1. Generate an age key once:

```bash
mkdir -p ~/.config/agenix
age-keygen -o ~/.config/agenix/key.txt
```

2. Persist your public key in Fish:

```fish
set -Ux AGENIX_USER_KEY (age-keygen -y ~/.config/agenix/key.txt)
```

3. Encrypt the secret files:

```bash
cd ~/NixConfig
mkdir -p secrets
agenix -e secrets/spotify-id.age
agenix -e secrets/spotify-secret.age
```

When each `agenix -e ...` opens your editor, paste only the raw value:

- `spotify-id.age`: paste the Client ID
- `spotify-secret.age`: paste the Client Secret

No quotes, no `KEY=...`, one value per file.

4. Apply Home Manager:

```bash
nh home switch
```

## Repo map

- `flake.nix`: inputs/outputs, host declarations, HM outputs
- `lib/mkHost.nix`: host builder + overlays + module wiring
- `modules/nixos/`: shared system-level modules
- `modules/home/`: Home Manager modules (shell, desktop, editor, apps)
- `hosts/<name>/`: host-specific overrides and hardware
- `disko/`: partition layouts used by installer
- `secrets.nix`: agenix recipient rules
- `check.sh`: standard pre-apply validation

## Wiki docs

Deep reference docs are under [`docs/wiki`](docs/wiki/README.md):

- [Architecture](docs/wiki/architecture.md)
- [Hosts and Disko](docs/wiki/hosts-and-disko.md)
- [Module reference](docs/wiki/modules-reference.md)
- [Desktop and shell UX](docs/wiki/desktop-and-shell.md)
- [Neovim stack](docs/wiki/neovim.md)
- [Operations](docs/wiki/operations.md)
- [Secrets and troubleshooting](docs/wiki/secrets-and-troubleshooting.md)
