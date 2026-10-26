# Flatpak & Sandboxed Applications Guide

This guide documents declarative Flatpak management in NixConfig: the Flathub remote, the declared application set, how activation-time installation works, and how apps that are *not* on Flathub are installed from GitHub releases without pinning versions or hashes.

---

## Overview

Flatpak support is enabled through a dedicated feature module, [`modules/features/system/flatpak/default.nix`](../../modules/features/system/flatpak/default.nix), and the [`nix-flatpak`](https://github.com/gmodena/nix-flatpak) flake module.

> **Why nix-flatpak?** NixOS' built-in `services.flatpak` only exposes `services.flatpak.enable` — it does not know how to declare remotes or applications. The `nix-flatpak` module layers the declarative `services.flatpak.remotes`, `services.flatpak.packages`, `services.flatpak.update`, and `services.flatpak.overrides` options on top of it.

| Layer | Technology | Purpose | Configuration |
| :--- | :--- | :--- | :--- |
| **Declarative manager** | **nix-flatpak** (`v0.7.0`) | Remotes, remote-backed packages, updates, overrides | `flake.nix` input |
| **Flathub remote** | `flathub` | Source repository for sandboxed apps | `modules/features/system/flatpak/default.nix` |
| **Roblox client** | **Sober** (`org.vinegarhq.Sober`) | Play, chat and explore on Roblox | Flathub (auto-updated) |
| **Launcher** | **Twintail Launcher** (`app.twintaillauncher.ttl`) | Game launcher | Flathub (auto-updated) |
| **Media player** | **Nuvio Desktop** (`com.nuvio.media.desktop`) | Stremio-addon media player | GitHub `releases/latest` (tracked, checksum-verified) |
| **Music player** | **Spotifast** (`rocks.spotifast.Spotifast`) | Native, lightweight Spotify client | GitHub `releases/latest` (tracked, checksum-verified) |
| **Runtime** | `org.gnome.Platform//50`, `org.freedesktop.Platform//25.08` | Sandbox runtimes pulled by Nuvio and Spotifast | Flathub (automatic) |

Both hosts (`desktop` and `laptop`) enable the feature:

```nix
features.flatpak.enable = true;
```

---

## Feature Options

| Option | Type | Purpose |
| :--- | :--- | :--- |
| `features.flatpak.enable` | `bool` | Enable Flatpak, Flathub, and the declarative app set. |
| `features.flatpak.packages` | list of app IDs / attrsets | Apps installed from a configured remote (normally Flathub). Passed straight to `services.flatpak.packages`. |
| `features.flatpak.bundles` | attrset of bundles | Apps installed from the **latest GitHub release** `.flatpak` asset. No version or hash is declared in Nix. |
| `features.flatpak.overrides` | attrset | Per-app sandbox overrides, merged into `services.flatpak.overrides`. |

The module's built-ins are normal option definitions, so a host (or another feature module) can add entries without restating them: lists concatenate and attrsets merge. Use `lib.mkForce` when you genuinely want to replace a built-in set.

---

## How Declarative Installation Works

Enabling the feature merges the `nix-flatpak` NixOS module and configures `services.flatpak`:

1. **Remote setup** — `services.flatpak.remotes` adds the Flathub repository to the *system* Flatpak installation (`/var/lib/flatpak`).
2. **Remote-backed packages** — a `flatpak-managed-install` **systemd oneshot** runs on activation. It compares the *old* state to the *new* state and:
   - installs newly declared packages,
   - uninstalls packages removed from `services.flatpak.packages`,
   - adds/removes remotes,
   - applies overrides.
3. **GitHub-release bundles** — a separate `flatpak-bundles` **systemd oneshot** runs after `flatpak-managed-install`. It waits for GitHub to be reachable (two minutes by default) so an offline boot is deferred to the timer instead of being logged as a failure. For every entry in `features.flatpak.bundles` it:
   - resolves the repository's `releases/latest` tag,
   - skips the download when the recorded tag matches and the app is still installed,
   - downloads the matching `.flatpak` asset,
   - verifies it against the release's checksum asset (`SHA256SUMS.txt` by default),
   - installs or updates the app with `flatpak install --or-update`,
   - records the installed tag in `/var/lib/flatpak-bundles/<appId>.tag`.
4. **State tracking** — nix-flatpak serialises its desired state to `/nix/var/nix/gcroots/flatpak-state.json`. Bundle state is tracked separately by the tag files above; a bundle already at the latest tag and still installed is not downloaded again.
5. **Portal assertion** — the stock Flatpak module asserts that `xdg.portal.enable = true`. This is already satisfied globally in [`modules/features/system/base.nix`](../../modules/features/system/base.nix).

> **Convergent, not exhaustive.** `services.flatpak.uninstallUnmanaged` defaults to `false`, so apps you install manually with `flatpak install` are left alone. Nuvio and Spotifast are intentionally *not* in `services.flatpak.packages`; they are unmanaged by nix-flatpak and owned by the `flatpak-bundles` service instead. Leave `uninstallUnmanaged = false` (the module asserts this when bundles are declared), otherwise nix-flatpak would remove tracked bundles on every activation.

Installed apps are exposed on the session `PATH` through `environment.profiles` (`/var/lib/flatpak/exports`), and Flatpak content lives in `/var/lib/flatpak` — **not** the Nix store, so `nix-collect-garbage` never reclaims it.

---

## Declared Applications

The module defaults are:

```nix
features.flatpak.packages = [
  "org.vinegarhq.Sober"
  "app.twintaillauncher.ttl"
];

features.flatpak.bundles."com.nuvio.media.desktop" = {
  owner = "NuvioMedia";
  repo = "NuvioDesktop";
  asset = "Nuvio-Linux-x86_64-{version}.flatpak";
};

features.flatpak.bundles."rocks.spotifast.Spotifast" = {
  owner = "crmne";
  repo = "spotifast";
  asset = "spotifast-{tag}-x86_64.flatpak";
  checksums = "checksums.txt";
};
```

### Sober (Roblox)

`org.vinegarhq.Sober` is a community-built Roblox client (`hid-playstation`-free, no VM/emulator) available on Flathub. Because Roblox forces client updates, Sober is refreshed on a schedule (see [Updates](#updates)).

### Nuvio Desktop

Nuvio Desktop is **not published on Flathub** — it is alpha software distributed only as direct downloads (`.AppImage`, `.deb`, `.rpm`, `.flatpak`) from [`NuvioMedia/NuvioDesktop` releases](https://github.com/NuvioMedia/NuvioDesktop/releases).

Rather than pinning a release in Nix, the module tracks the upstream latest release whenever the `flatpak-bundles` unit is started at activation, and once a day via its timer. The release tag (`0.1.32-alpha`, `0.1.33-alpha`, …) is substituted into the asset filename, downloaded, checked against the release's `SHA256SUMS.txt`, and installed. Nothing in the Nix configuration needs bumping when Nuvio releases.

> **Trust model.** The bundle comes from GitHub over TLS and is verified against a checksum published in the same release. That catches corruption and truncated downloads, but not a compromised upstream release. The trade-off is deliberate for alpha software; use the pinned `services.flatpak.packages` escape hatch below if you need Nix-level integrity.

### Spotifast

Spotifast (`rocks.spotifast.Spotifast`) is a native Rust Spotify client that is **not published on Flathub**. It ships a Flatpak bundle on [`crmne/spotifast` releases](https://github.com/crmne/spotifast/releases) and lists its checksums in `checksums.txt`. Playback requires Spotify Premium; free accounts can browse but not play through Spotifast. The module tracks its latest release in the same way as Nuvio.

---

## Adding or Removing Applications

### Flathub / remote-backed app

Add the application ID to `features.flatpak.packages`:

```nix
# modules/hosts/desktop/configuration.nix (or any module)
features.flatpak.packages = [
  "com.spotify.Client"          # ← new
];
```

Because the module and the host both define the list normally, this **appends** to the built-in Sober/Twintail entries rather than replacing them. Use `features.flatpak.packages = lib.mkForce [ ... ];` to replace the whole list instead.

- **Adding** an entry installs it on the next `nh os switch`.
- **Removing** an entry uninstalls it on the next activation.
- Find IDs with `flatpak search <name>` or on [flathub.org](https://flathub.org).

### GitHub-release bundle

Add an entry keyed by application ID:

```nix
features.flatpak.bundles."com.example.App" = {
  owner = "example";
  repo = "ExampleApp";
  asset = "Example-{version}-x86_64.flatpak";   # {tag} = full tag, {version} = tag without a leading "v"
  checksums = "SHA256SUMS.txt";                # default; null disables verification
};
```

- **`asset` / `checksums` templates** — `{tag}` expands to the full release tag (`v1.2.3`) and `{version}` expands to the tag with a leading `v` removed (`1.2.3`).
- **`checksums`** — defaults to `SHA256SUMS.txt`; set it to another asset name if upstream uses one. Set it to `null` only if the project publishes no checksums (not recommended).
- **Updates** — no rebuild is needed for a new upstream release. The daily `flatpak-bundles` timer picks it up; run `sudo systemctl start flatpak-bundles` to check immediately.
- **`releases/latest`** — follows GitHub's definition of "latest", which excludes releases explicitly marked pre-release. If an app only publishes prereleases, track it a different way.
- **Debugging a bad asset name** — the service logs the resolved URL before failing, so `journalctl -u flatpak-bundles` shows exactly what it tried.
- **Missing launcher icon** — some bundles only export a scalable SVG icon. The service links the bundle's raster AppStream PNGs into the exported `hicolor` theme and refreshes the icon cache as a fallback for launchers that cannot load SVG theme icons. Restart the launcher (or log out/in) if it cached the missing icon during the first install.

> **Removing a tracked bundle** — deleting the entry stops future updates but leaves the app installed (nix-flatpak does not manage it). Remove it with `flatpak uninstall --system <appId>`, delete `/var/lib/flatpak-bundles/<appId>.tag`, and use `features.flatpak.bundles = lib.mkForce { ... };` to replace the built-in bundle set.

> If you need strict Nix reproducibility for a bundle, opt out of tracking by declaring it in `services.flatpak.packages` with a `fetchurl`-pinned `bundle` instead. That reintroduces the version/hash bumps this module deliberately avoids.

---

## Updates

Both update paths are scheduled daily and catch up after the machine was off:

| Behaviour | Scope | Timer |
| :--- | :--- | :--- |
| Flathub app updates | Remote-backed apps such as **Sober** and **Twintail** | `flatpak-managed-install-timer` |
| GitHub-release bundle updates | Bundles such as **Nuvio** and **Spotifast** | `flatpak-bundles.timer` |

```nix
# Flathub side (nix-flatpak)
update.auto = {
  enable = true;
  onCalendar = "daily";
};
```

The bundle installer is idempotent: if the recorded tag matches `releases/latest` and the app is still installed, it exits without downloading the (large) `.flatpak` again.

> Unlike most Nix-managed software, Flatpak apps update over the network independently of `nixos-rebuild`. This is a deliberate trade-off so Sober keeps matching the live Roblox version and GitHub-release apps like Nuvio and Spotifast can be tracked without constant hash bumps.

---

## Manual Commands

```bash
# List installed system apps
flatpak --system list --app

# Inspect an app (version, commit, runtime)
flatpak --system info com.nuvio.media.desktop

# Run an app directly
flatpak run com.nuvio.media.desktop
flatpak run rocks.spotifast.Spotifast
flatpak run org.vinegarhq.Sober

# Search / browse Flathub
flatpak search roblox
flatpak --system remote-ls flathub | grep -i sober

# Force a bundle update check now
sudo systemctl start flatpak-bundles
journalctl -u flatpak-bundles -b --no-pager
```

---

## Overrides & Sandboxing

Per-app sandbox permissions can be declared rather than set with `flatpak override`:

```nix
features.flatpak.overrides."com.nuvio.media.desktop".Context.sockets = [
  "wayland"
  "!x11"
];
```

The module ships the Twintail Launcher NVIDIA/WebKitGTK override this way. Overrides are merged recursively with the built-in ones; to remove a built-in entry entirely, override `features.flatpak.overrides` with `lib.mkForce { ... }`.

> nix-flatpak v0.7.0 has no `overrides.writeMode`; its override files are written by the activation service and merged with externally applied changes.

---

## Troubleshooting

### Remote-backed installation did not run or failed

```bash
# Inspect the activation-time installer
systemctl status flatpak-managed-install
journalctl -u flatpak-managed-install -b

# Force a re-run of the installer
sudo systemctl restart flatpak-managed-install
```

### Bundle installation did not run or failed

```bash
systemctl status flatpak-bundles
journalctl -u flatpak-bundles -b --no-pager

# Force a check now
sudo systemctl start flatpak-bundles

# See which upstream tag was last installed
cat /var/lib/flatpak-bundles/com.nuvio.media.desktop.tag
cat /var/lib/flatpak-bundles/rocks.spotifast.Spotifast.tag
```

Common failures:

- **`cannot resolve the latest release`** — GitHub is still unreachable after the install service waited, or the repository/owner is wrong. An offline boot is not an error; the service leaves the bundles for the daily timer. Run `sudo systemctl start flatpak-bundles` once the network is up.
- **`failed to download`** — the `asset` template does not match the release asset name. Check the release page; remember `{version}` strips a leading `v`.
- **`checksum mismatch`** — the download was corrupted or upstream replaced the asset without bumping the tag. Re-run once; if it persists, inspect the release.
- **`has no entry for ...`** — upstream changed the checksum asset or the asset name. Update `checksums` / `asset`.

### Verify tracked state

```bash
# nix-flatpak's remote-backed state
sudo cat /nix/var/nix/gcroots/flatpak-state.json

# Bundle tags recorded by flatpak-bundles
sudo ls -l /var/lib/flatpak-bundles
```

### A bundle fails to launch / missing runtime

Nuvio needs `org.gnome.Platform//50` and Spotifast needs `org.freedesktop.Platform//25.08` from Flathub. Confirm the remote is reachable and the runtimes are present:

```bash
flatpak --system remotes
flatpak --system list --runtime | grep -E 'org\.(gnome|freedesktop)\.Platform'
```

### New app entry does nothing

- Remote-backed packages only take effect **on activation**; rebuild with `nh os switch`.
- Bundles are checked at activation and then daily. After a rebuild, a new upstream release is only picked up when the timer next fires or you run `sudo systemctl start flatpak-bundles`.
- If the entry is in a brand-new file, remember flakes ignore untracked files — `git add` it first.

---

## File Reference

| Path | Role |
| :--- | :--- |
| `modules/features/system/flatpak/default.nix` | Feature module: enable toggle, Flathub remote, package/bundle/override options, bundle service |
| `modules/features/system/flatpak/bundles.sh` | Bundle installer: network wait, release lookup, checksum verification and icon fallback |
| `flake.nix` | `nix-flatpak` input (`v0.7.0`) |
| `/var/lib/flatpak` | System Flatpak installation and app data |
| `/var/lib/flatpak-bundles` | Last installed upstream tag per GitHub-release bundle |
| `/nix/var/nix/gcroots/flatpak-state.json` | nix-flatpak managed-state file |
