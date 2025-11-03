# Minecraft Stack — Paper + Velocity + WireGuard

This service stack powers a two-node Minecraft setup using a secure, containerized backend and an encrypted public proxy.  
It demonstrates how isolated Docker networks, WireGuard tunnels, and strict firewalling can provide public gameplay without exposing the home network.

---

## Overview

| Component | Host | Network | Purpose |
|------------|------|----------|----------|
| **Velocity** | Remote VPS (edge node) | Public port `25565` + WireGuard (`10.8.0.1`) | Public proxy → Paper backend |
| **Paper** | Home node | Isolated `mc_net` ↔ `mc_pub` bridge (`10.8.0.2`) | Actual Minecraft world backend |
| **WireGuard** | VPS ↔ Home node | `10.8.0.0/24` private tunnel | Secure transport, CGNAT bypass |

Traffic never traverses the internet in plaintext:
```

Player → Velocity (VPS) → WireGuard → Paper (Home)

```

No router port forwarding is used.  
Only the VPS’s port `25565/tcp` is reachable — and even that is UFW-restricted to the WireGuard peer IP.

---

## Runtime Profile

| Setting | Value |
|----------|--------|
| RAM | 4 GB allocated to Paper by default |
| Mode | Offline (authentication handled by Velocity proxy) |
| Whitelist | Enabled — only approved UUIDs allowed |
| Max players | 10 (default) |
| Autosave | Every 5 minutes |
| Backups | Hourly via cron → `/mnt/data/backups/paper/` |

Both `server.properties` and `paper-global.yml` are Ansible-templated.  
Runtime tuning (RAM, whitelist, secrets) is managed through inventory variables.

---

## Role Responsibilities

### `roles/paper`
- Deploys a **rootless PaperMC container** (from `ghcr.io/papermc/paper`) under UID/GID 1000  
- Connects only to:
  - `mc_pub` (WireGuard bridge)
  - `mc_net` (isolated backend)
- Templates:
  - `server.properties.j2`
  - `paper-global.yml.j2`
  - `velocity.secret` (shared hash with proxy)
- Enforces **offline mode** and **whitelist-only access**
- Applies persistent iptables (`DOCKER-USER`) rules:
  - `ACCEPT` from VPS WireGuard IP  
  - `DROP` all others
- Includes backup and verification tasks

**Gotcha:**  
The forwarding secret must come from a single variable (e.g. `vault_velocity_forwarding_secret`).  
Avoid circular defaults like `velocity_forwarding_secret | default(vault_velocity_forwarding_secret)`.

---

### `roles/velocity`
- Bare-metal Java service on the VPS, managed by systemd (`/opt/velocity/velocity.jar`)
- Exposes port `25565/tcp` publicly; restricted via UFW to the home node’s VPN IP
- Forwards players to `10.8.0.2:25565`
- Uses **modern forwarding mode** with a **shared secret** for player info pass-through

**Gotchas**
- Secret mismatch → *“Player info forwarding is disabled!”*  
  → Ensure the same secret is deployed on both nodes
- Keep working directory (`/opt/velocity/`) with:
  - `velocity.toml`
  - `servers.toml`
- When upgrading, back up configs before replacing the JAR

---

### `roles/wireguard-server` / `roles/wireguard-client`
- Provide encrypted VPN tunnel between nodes
- Server (VPS): `10.8.0.1/24`, listens `51820/udp`
- Client (Home): `10.8.0.2/24`, peers with server
- Enables IP forwarding + NAT only for game traffic

**Gotcha:**  
Re-apply iptables after reboot; Docker and UFW may flush WireGuard chains.  
Persistent keys are stored in `/etc/wireguard/wg0.conf`.

---

## Isolation & Security

- **Paper** is reachable only via the WireGuard tunnel — never from LAN or WAN  
- **Velocity** has no backend awareness beyond its forwarding secret  
- No bridge between `mc_net` / `mc_pub` and any other Docker network  
- All Minecraft traffic is:
  - Encrypted (WireGuard)
  - Authenticated (Velocity forwarding + whitelist)
- **Backups & logs** stay local on LAN storage (SSD/HDD)

---

## Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|----------|---------------|------|
| Players can’t join | WireGuard tunnel down | Run `sudo wg show` on both nodes |
| “Player info forwarding is disabled” | Secret mismatch | Re-sync `vault_velocity_forwarding_secret` |
| Lag spikes | Paper memory cap too low | Raise `paper_memory` in group vars |
| Timeout during join | Firewall restriction | Verify VPS UFW rules: `sudo ufw status` |
| “Unknown host” in logs | Wrong `server-ip` | Ensure `10.8.0.2` in `server.properties` |

---

## Summary

This setup provides:
- End-to-end encryption for all game sessions  
- Total network isolation of backend services  
- Automated deployment, updates, and backups  
- Secure access for whitelisted players only  
- Fully reproducible infrastructure as code (via Ansible)

