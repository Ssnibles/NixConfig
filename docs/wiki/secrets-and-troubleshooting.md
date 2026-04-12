# Secrets and troubleshooting

## Agenix + Spotify secrets

This repo expects these encrypted files:

- `secrets/spotify-id.age`: Spotify Client ID
- `secrets/spotify-secret.age`: Spotify Client Secret

Get both values from: <https://developer.spotify.com/dashboard>

### Bootstrap

```bash
mkdir -p ~/.config/agenix
age-keygen -o ~/.config/agenix/key.txt
```

For Fish, persist recipient key:

```fish
set -Ux AGENIX_USER_KEY (age-keygen -y ~/.config/agenix/key.txt)
```

Encrypt/edit values:

```bash
cd ~/NixConfig
mkdir -p secrets
agenix -e secrets/spotify-id.age
agenix -e secrets/spotify-secret.age
```

Paste only the raw credential value in each file (no quotes, no env-var prefix).

Apply:

```bash
nh home switch
```

## Common warnings and what they mean

### `trusted-public-keys ... restricted setting`

This warning appears for unprivileged users and is usually non-blocking with `nh`.

### `Spotify credentials are not configured`

Expected until both `secrets/spotify-id.age` and `secrets/spotify-secret.age` exist and are decryptable.

### `service manager is degraded`

A user service failed (for example `swaync.service`). Check:

```bash
systemctl --user reset-failed
systemctl --user restart swaync.service
journalctl --user -u swaync.service -n 80 --no-pager
```

### `attribute "secrets/spotify-*.age" missing` from `agenix -e`

This happens when secret rule names and command paths do not match.  
Current repo rules are keyed by:

- `"secrets/spotify-id.age"`
- `"secrets/spotify-secret.age"`

So commands must include the `secrets/` prefix.
