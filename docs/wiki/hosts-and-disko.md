# Hosts and Disko

## Host matrix

| Host | Profile flags | Notes |
|---|---|---|
| `desktop` | `isLaptop = false`, `hasNvidia = true`, `useDisko = true` | NVIDIA module enabled, desktop performance defaults |
| `laptop` | `isLaptop = true`, `hasNvidia = false`, `useDisko = true` | TLP + laptop power tuning |
| `desktop-test` | same as desktop, `useDisko = false` | Safe rebuild target without repartitioning |
| `laptop-test` | same as laptop, `useDisko = false` | Safe rebuild target without repartitioning |

## Host-specific modules

- `hosts/desktop/default.nix`
  - performance governor
  - resolved DNSSEC/DoT relaxed for reliability
  - desktop udev tuning
  - reduced background services (no Ollama autostart, printing discovery off, Bluetooth on-demand)
- `hosts/laptop/default.nix`
  - Realtek/iwd Wi-Fi quirks
  - TLP profile (AC/BAT behavior, charge thresholds)
  - lid handling

Hardware files:

- `hosts/desktop/hardware.nix`
- `hosts/laptop/hardware.nix`

They provide legacy filesystem/swap declarations when `useDisko = false`.

## Disk layouts

- `disko/desktop.nix`
  - GPT
  - EFI: 512M (`/boot`, vfat)
  - root: remainder (`/`, ext4)

- `disko/laptop.nix`
  - GPT
  - EFI: 512M (`/boot`, vfat)
  - swap: 8G (resume enabled)
  - root: remainder (`/`, ext4)

`install.sh` uses Disko for fresh installs and passes target disk via:

```bash
--argstr diskDevice /dev/<disk>
```
