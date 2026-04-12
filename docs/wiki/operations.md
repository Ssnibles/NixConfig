# Operations

## Standard validation

From repo root:

```bash
bash ./check.sh
```

Use this before applying major config changes.

## Apply changes

### Full system

```bash
nh os switch
```

Use for kernel, drivers, boot loader, system services, firewall/network stack, etc.

### Home Manager only

```bash
nh home switch
```

Use for shell config, Hyprland/Waybar/SwayNC, Neovim, user packages, and HM-managed services.

Explicit target if needed:

```bash
nh home switch -c josh@desktop
```

## Dependency updates

```bash
nix flake update
```

Then re-run `bash ./check.sh` and apply changes.

## Useful day-2 commands

```bash
# inspect available hosts
nix flake show --all-systems | rg nixosConfigurations

# evaluate a system build output
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel

# restart a failing user service and inspect logs
systemctl --user restart swaync.service
journalctl --user -u swaync.service -n 80 --no-pager
```
