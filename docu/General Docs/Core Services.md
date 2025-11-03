# Core Services

Tresor is structured as a two-tier infrastructure, consisting of an on-premises Docker-based homelab and a minimal remote VPS edge node.

---

## Architecture Overview

| Layer | Node | Role |
|--------|------|------|
| **Edge (VPS)** | `tresor-vps` | Public entry point hosting WireGuard and Velocity (Minecraft proxy) |
| **Core (Homelab)** | `tresor` | Private Docker-based host running PaperMC, Traefik, and all internal services |

The VPS acts as a hardened, low-surface public interface, while Tresor hosts all applications and containers internally.  
All web access is routed through Cloudflare Tunnel and Traefik, and no TCP game traffic passes through Cloudflare.

Minecraft connectivity flows exclusively through the WireGuard tunnel established between the VPS and the home node.

---

## Public-Facing Services (`public_net`)

| Service | Purpose | Notes |
|----------|----------|-------|
| **Traefik** | Reverse proxy for all HTTP(S) services, including TLS termination, rate limiting, and security headers | Handles all ingress from Cloudflare Tunnel |
| **Cloudflare Tunnel** | Secure public exposure for web applications without port forwarding | Cloudflare → Tresor (no open inbound ports) |
| **Uptime Kuma** | Public status page | Monitors LAN and publicly accessible services |
| **Landing Site** | `/devops` (project CV) and `/photo` (personal gallery) | Static content served via Traefik through Cloudflare Tunnel |

> **Note:**  
> No TCP game traffic is routed through Cloudflare Tunnel.  
> Minecraft access is handled entirely through Velocity on the VPS.

---

## External Services (VPS Layer)

| Service | Host | Purpose | Exposed | Notes |
|----------|------|----------|----------|-------|
| **Velocity (Minecraft Proxy)** | `tresor-vps` | Public entry point for Minecraft clients | Yes — `25565/tcp` | Runs as a systemd service; forwards to PaperMC via WireGuard (`10.8.0.2:25565`) |
| **WireGuard Daemon** | `tresor-vps` and `tresor` | Encrypted tunnel between VPS and homelab | Yes — `51820/udp` | Handles all Minecraft traffic and control RPCs |
| **UFW + Fail2Ban** | `tresor-vps` | Host-level security and brute-force protection | Yes | Default-deny policy; allows only SSH, WireGuard, and Velocity |

---

## Internal Services (`internal_net`)

| Service | Purpose | Notes |
|----------|----------|-------|
| **Grafana** | Visualization dashboard | Displays system and container metrics |
| **Prometheus** | Metrics collector | Scrapes exporters across the internal network |
| **cAdvisor** | Container metrics exporter | Tracks container resource usage |
| **Node Exporter** | Host-level metrics exporter | Exposes CPU, memory, and disk data |
| **Jellyfin** | Media server | LAN-only streaming for music and video |
| **File Browser** | Web-based file manager | Read/write access to `/mnt/data` shares |

All of these services are LAN-only and not exposed publicly.

---

## Isolated Minecraft Backend (`mc_net`)

| Service | Purpose | Exposed | Notes |
|----------|----------|----------|-------|
| **Paper (Minecraft Server)** | Main game server backend (whitelist-only) | Indirectly (via WireGuard + Velocity) | Runs in Docker on `tresor`, bound to `10.8.0.2:25565`; receives all player connections forwarded from the VPS |

---

## Operational Notes

- **Public TCP exposure:** Only Velocity (`25565/tcp`) on the VPS is exposed to the internet.  
- **Minecraft routing:** All gameplay traffic is encapsulated in WireGuard between `10.8.0.1` (VPS) and `10.8.0.2` (home node).  
- **Web exposure:** Cloudflare Tunnel → Traefik → service container; no open inbound ports.  
- **Security controls:** UFW and Fail2Ban are active on both VPS and home node.  
- **Access policy:** No root logins; SSH key authentication only.  
- **Containerization:** All internal services run within Docker under non-root contexts.  

---

This architecture minimizes public exposure, isolates Minecraft traffic from web infrastructure, and maintains complete privacy for the home environment.  
Only the edge VPS handles inbound connections, while the home node remains fully internal, automated, and accessible solely through secure tunnels.
