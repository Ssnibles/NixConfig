# Flatpak & Sandboxed Applications Guide

This guide documents declarative Flatpak management in NixConfig: the Flathub remote, the declared application set, how activation-time installation works, and how to pin the Nuvio Desktop bundle that is not published on Flathub.

---

## Overview

Flatpak support is enabled through a dedicated feature module, [`modules/features/system/flatpak.nix`](../../modules/features/system/flatpak.nix), and the [`nix-flatpak`](https://github.com/gmodena/nix-flatpak) flake module.

> **Why nix-flatpak?** NixOS' built-in `services.flatpak` only exposes `services.flatpak.enable` — it does not know how to declare remotes or applications. The `nix-flatpak` module layers the declarative `services.flatpak.remotes`, `services.flatpak.packages`, `services.flatpak.update`, and `services.flatpak.overrides` options on top of it.

| Layer | Technology | Purpose | Configuration |
| :--- | :--- | :--- | :--- |
| **Declarative manager** | **nix-flatpak** (`v0.7.0`) | Remotes, packages, updates, overrides | `flake.nix` input |
| **Flathub remote** | `flathub` | Source repository for sandboxed apps | `modules/features/system/flatpak.nix` |
| **Roblox client** | **Sober** (`org.vinegarhq.Sober`) | Play, chat and explore on Roblox | Flathub (auto-updated) |
| **Media player** | **Nuvio Desktop** (`com.nuvio.media.desktop`) | Stremio-addon media player | Hash-pinned GitHub `.flatpak` bundle |
| **Runtime** | `org.gnome.Platform//50` | Sandbox runtime pulled by Nuvio | Flathub (automatic) |

Both hosts (`desktop` and `laptop`) enable the feature:

```nix
features.flatpak.enable = true;
```

---

## How Declarative Installation Works

Enabling the feature merges the `nix-flatpak` NixOS module and configures `services.flatpak`:

1. **Remote setup** — `services.flatpak.remotes` adds the Flathub repository to the *system* Flatpak installation (`/var/lib/flatpak`).
2. **Activation-time install** — a `flatpak-managed-install` **systemd oneshot** runs on every activation (`wantedBy = [ "default.target" ]`). It compares the *old* state to the *new* state and:
   - installs newly declared packages,
   - uninstalls packages removed from `services.flatpak.packages`,
   - adds/removes remotes,
   - applies overrides.
3. **State tracking** — the desired state is serialised to JSON and symlinked to `/nix/var/nix/gcroots/flatpak-state.json` (kept out of the GC). Editing the package list is what drives installs and removals.
4. **Portal assertion** — the stock Flatpak module asserts that `xdg.portal.enable = true`. This is already satisfied globally in [`modules/features/system/base.nix`](../../modules/features/system/base.nix).

> **Convergent, not exhaustive.** `services.flatpak.uninstallUnmanaged` defaults to `false`, so apps you install manually with `flatpak install` are left alone. Only the declared package set is managed.

Installed apps are exposed on the session `PATH` through `environment.profiles` (`/var/lib/flatpak/exports`), and Flatpak content lives in `/var/lib/flatpak` — **not** the Nix store, so `nix-collect-garbage` never reclaims it.

---

## Declared Applications

```nix
services.flatpak.packages = [
  # Flathub app: Roblox client for Linux.
  "org.vinegarhq.Sober"

  # Not on Flathub: pinned release bundle from GitHub.
  {
    appId = "com.nuvio.media.desktop";
    sha256 = nuvioHash;
    bundle = "${pkgs.fetchurl {
      url = nuvioUrl;
      hash = nuvioHash;
    }}";
  }
];
```

### Sober (Roblox)

`org.vinegarhq.Sober` is a community-built Roblox client (`hid-playstation`-free, no VM/emulator) available on Flathub. Because Roblox forces client updates, Sober is refreshed on a schedule (see [Updates](#updates)).

### Nuvio Desktop

Nuvio Desktop is **not published on Flathub** — it is alpha software distributed only as direct downloads (`.AppImage`, `.deb`, `.rpm`, `.flatpak`) from [`NuvioMedia/NuvioDesktop` releases](https://github.com/NuvioMedia/NuvioDesktop/releases). NixConfig installs the official `.flatpak` bundle pinned by hash.

---

## Adding or Removing Applications

Any Flathub app can be added by its application ID:

```nix
services.flatpak.packages = [
  "org.vinegarhq.Sober"
  "com.spotify.Client"          # ← new
];
```

- **Adding** an entry installs it on the next `nh os switch`.
- **Removing** an entry uninstalls it on the next activation.
- Find IDs with `flatpak search <name>` or on [flathub.org](https://flathub.org).

---

## Updating the Nuvio Bundle

Nuvio releases frequently, so its version and hash are declared at the top of [`flatpak.nix`](../../modules/features/system/flatpak.nix):

```nix
nuvioVersion = "0.1.27-alpha";
nuvioHash = "sha256-iUZNxC8P1UyNKOE9TJCymuEWFkxveR5/oISsKRkm4aA=";
nuvioUrl = "https://github.com/NuvioMedia/NuvioDesktop/releases/download/${nuvioVersion}/Nuvio-Linux-x86_64-${nuvioVersion}.flatpak";
```

To bump:

1. Set `nuvioVersion` to the new release tag (e.g. `"0.1.28-alpha"`).
2. Refresh `nuvioHash`, either:
   ```bash
   nix-prefetch-url "https://github.com/NuvioMedia/NuvioDesktop/releases/download/<v>/Nuvio-Linux-x86_64-<v>.flatpak"
   ```
   or take that file's `sha256` from the release's `SHA256SUMS.txt` and convert it:
   ```bash
   nix hash convert --hash-algo sha256 --to sri <hex>
   ```
3. Rebuild. Because the bundle hash changed, nix-flatpak uninstalls the old app and installs the new one automatically.

---

## Updates

`services.flatpak.update.auto` schedules periodic updates of remote-backed (Flathub) apps:

```nix
update.auto = {
  enable = true;
  onCalendar = "daily";
};
```

| Behaviour | Scope |
| :--- | :--- |
| Auto-update (daily) | Flathub apps such as **Sober** |
| Never auto-updated | The **Nuvio** bundle, which is hash-pinned and only changes when `nuvioHash` changes |

The scheduler registers a `flatpak-managed-install-timer` systemd timer with `Persistent = "true"`, so a run that was missed while the machine was off fires on resume. Set `auto.enable = false` to update Flathub apps manually.

> Unlike most Nix-managed software, Flatpak apps update over the network independently of `nixos-rebuild`. This is a deliberate trade-off so Sober keeps matching the live Roblox version.

---

## Manual Commands

```bash
# List installed system apps
flatpak --system list --app

# Inspect an app (version, commit, runtime)
flatpak --system info com.nuvio.media.desktop

# Run an app directly
flatpak run com.nuvio.media.desktop
flatpak run org.vinegarhq.Sober

# Search / browse Flathub
flatpak search roblox
flatpak --system remote-ls flathub | grep -i nuvio
```

---

## Overrides & Sandboxing

Per-app sandbox permissions can be declared rather than set with `flatpak override`:

```nix
services.flatpak.overrides.settings = {
  "com.nuvio.media.desktop".Context.sockets = [ "wayland" "!x11" ];
};
```

By default nix-flatpak merges declared overrides with any externally applied ones; set `overrides.writeMode = "replace"` to let Nix fully own the override file.

---

## Troubleshooting

### Installation did not run or failed

```bash
# Inspect the activation-time installer
systemctl status flatpak-managed-install
journalctl -u flatpak-managed-install -b

# Force a re-run of the installer
sudo systemctl restart flatpak-managed-install
```

### Verify the tracked state

```bash
sudo cat /nix/var/nix/gcroots/flatpak-state.json
```

### Nuvio fails to launch / missing runtime

The bundle needs `org.gnome.Platform//50` from Flathub. Confirm the remote is reachable and the runtime present:

```bash
flatpak --system remotes
flatpak --system list --runtime | grep org.gnome.Platform
```

### New app entry does nothing

Removing or adding a package only takes effect **on activation**. Rebuild (`nh os switch`); if the entry is a brand-new file, remember flakes ignore untracked files — `git add` it first.

---

## File Reference

| Path | Role |
| :--- | :--- |
| `modules/features/system/flatpak.nix` | Feature module: feature toggle, Flathub remote, package set, Nuvio pin, updates |
| `flake.nix` | `nix-flatpak` input (`v0.7.0`) |
| `/var/lib/flatpak` | System Flatpak installation and app data |
| `/nix/var/nix/gcroots/flatpak-state.json` | nix-flatpak managed-state file |
