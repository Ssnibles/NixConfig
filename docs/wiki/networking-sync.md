# Networking, Tailscale & Syncthing Synchronization

This guide documents the networking stack, Tailscale mesh VPN, Syncthing peer-to-peer file synchronization, and encrypted DNS configurations in NixConfig.

---

## Overview

The network architecture is designed for secure inter-device connectivity, private AI model communication, and background synchronization that preserves laptop battery life:

| Subsystem | Technology | Purpose | Configuration Module |
| :--- | :--- | :--- | :--- |
| **Mesh VPN** | **Tailscale** | Zero-config WireGuard mesh network between hosts | `modules/features/system/tailscale.nix` |
| **File Sync** | **Syncthing** | Continuous peer-to-peer sync with homeserver | `modules/features/system/syncthing.nix` |
| **Encrypted DNS** | **systemd-resolved** | DNS-over-TLS with Cloudflare and Google fallbacks | `modules/features/system/base.nix` |
| **Wireless Stack** | **iwd + NetworkManager** | High-performance Wi-Fi with Opportunistic Wireless Encryption | `modules/features/system/base.nix` |

---

## Tailscale Mesh VPN

Tailscale provides an encrypted, peer-to-peer WireGuard mesh overlay connecting your desktop, laptop, and local homeserver regardless of physical location.

### NixOS Configuration

Defined in `modules/features/system/tailscale.nix`:

```nix
features.tailscale.enable = true;
```

Key settings applied:
- **Routing Role**: Configured as a client (`useRoutingFeatures = "client"`).
- **Firewall Integration**:
  - `tailscale0` interface is added to `networking.firewall.trustedInterfaces`, permitting traffic between trusted tailnet nodes.
  - The Tailscale WireGuard UDP communication port is opened dynamically.
  - Reverse path filtering set to loose (`checkReversePath = "loose"`) to allow asymmetric WireGuard routing paths without dropping packets.

### Inter-Service Integration

Tailscale acts as the secure backbone for multiple services in this configuration:
1. **Hermes AI Inference**: The Hermes agent routes inference requests to the homeserver Ollama daemon over Tailscale (`100.124.73.101:11434`), see [AI Tools Guide](ai-tools.md).
2. **Remote SSH & Administration**: Connect to remote hosts directly by Tailscale hostname or IP without port forwarding.

### Useful Commands

```bash
# Check status and connected nodes on your tailnet
tailscale status

# Bring up or re-authenticate connection
sudo tailscale up

# Check network connectivity and latency to a node
tailscale ping homeserver
```

---

## Syncthing Peer-to-Peer File Synchronization

Syncthing is configured in `modules/features/system/syncthing.nix` to synchronize essential directories between workstations, laptops, and the central homeserver without third-party cloud reliance.

### Synchronized Folders

| Folder Label | Path | Sync ID | Target Device |
| :--- | :--- | :--- | :--- |
| **Documents** | `~/Documents` | `pfqwn-dke5x` | `homeserver` |
| **Hermes** | `~/Hermes` | `tuyqy-adrau` | `homeserver` |

### Battery & Mobile Optimizations

Standard Syncthing defaults maintain continuous internet relay connections and global discovery broadcasts, which consume background CPU cycles and drain laptop battery. NixConfig applies aggressive power-saving constraints:

- **Global Discovery Disabled** (`globalAnnounceEnabled = false`): Stops sending broadcast packets to public internet discovery servers.
- **Relays Disabled** (`relaysEnabled = false`): Prevents routing traffic through high-latency public relay nodes.
- **NAT Traversal Disabled** (`natEnabled = false`): Avoids UPnP port mapping overhead.
- **Local Wi-Fi Discovery** (`localAnnounceEnabled = true`): Retains direct, high-speed synchronization whenever devices share a local network.
- **Anonymous Metrics Disabled** (`urAccepted = -1`): Eliminates background telemetry pings.

### Boot Latency Optimization

By default, the upstream NixOS Syncthing service is ordered into `multi-user.target`, which can introduce a 1.5 to 2.0 second blocking delay during early system boot.

NixConfig overrides service ordering:
```nix
systemd.services.syncthing.wantedBy = lib.mkForce [ "graphical.target" ];
systemd.services.syncthing-init.wantedBy = lib.mkForce [ "graphical.target" ];
```
This defers Syncthing startup until after the graphical environment has initialized, ensuring instantaneous boot to desktop.

### Web GUI Access

Syncthing includes a local web management interface:
- **URL**: `http://127.0.0.1:8384`
- **Theme**: Dark mode configured by default.

---

## Encrypted DNS & Wireless Stack

Configured in `modules/features/system/base.nix`:

### DNS-over-TLS (DoT)

System DNS resolution is handled by `systemd-resolved` with opportunistic DNS-over-TLS encryption:
- **Primary DNS**: Cloudflare (`1.1.1.1#cloudflare-dns.com`, `1.0.0.1#cloudflare-dns.com`)
- **Fallback DNS**: Google DNS (`8.8.8.8#dns.google`, `8.8.4.4#dns.google`)
- **DNSSEC**: Disabled to prevent broken resolution on captive portals and local subnets.

### NetworkManager + iwd

- **iwd Backend**: NetworkManager uses Intel Wireless Daemon (`iwd`) instead of `wpa_supplicant` for faster Wi-Fi association, lower background memory consumption, and reliable roaming.
- **Opportunistic Wireless Encryption (OWE)**: Enabled (`EnableOWE = true`), automatically encrypting traffic on open Wi-Fi networks supporting Enhanced Open (Wi-Fi 6).
- **Wi-Fi Powersave**: Disabled (`powersave = false`) to guarantee consistent low ping during SSH sessions and gaming.
- **TCP MTU Probing**: Enabled (`net.ipv4.tcp_mtu_probing = 1`), automatically detecting and clamping MTU when black holes occur (e.g., PPPoE 1480 MTU).
