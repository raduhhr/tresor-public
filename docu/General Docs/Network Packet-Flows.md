# Network Packet Flows — Example Homelab Architecture  
*(Sanitized – Updated November 2025)*

High-level network model used by the example homelab environment.  
All addressing, hostnames, and network identifiers are illustrative only.

---

## Design Overview
The network enforces explicit, least-privilege connectivity.  
No service or container communicates outside its designated network segment.  
All public ingress is routed through an encrypted tunnel and reverse proxy.

---

## High-Level Topology (Simplified ASCII Diagram)

```
        _____________________Internet                             
        |                       │					 lan_pub (LAN bridge)
        |             Cloudflare Tunnel (HTTPS 443)                      ────────────────────
        |                       │                                                │
        |                       |                                                │
        |                    Traefik  (HTTP)                            internal_net (LAN-only)
        |                       │                                       ───────────────────────
        |                  public_net                                    • Jellyfin
        |               (exposed via CF)                                 • FileBrowser
        |              ─────────────────                                 • Grafana
        |              • Uptime Kuma                                     • Prometheus
        |           
        |                                
        |
Velocity MC Proxy-----------------------------------------|
──────────────────────────                                |
• Hetzner VPS (WireGuard Server 10.8.0.1)                 |
• Public 25565 / UFW protected                            |
                                                          |
                                            mc_pub (WireGuard Client Iface)
                                            ─────────────────────────────
                                            • bridge → mc_net (PaperMC)
                                                           │
                                                           ▼
                                                mc_net (isolated backend)
                                                ─────────────────────────
                                                • PaperMC (Docker)
                                                • whitelist-only, offline             
```

## Core Docker Networks (Home Node)

| Network | Scope | Purpose | Example Services |
|----------|--------|----------|------------------|
| `mc_net` | Isolated | Backend game service | Game container only |
| `public_net` | Internet-facing | Public web exposure via Cloudflare-style tunnel and proxy | Reverse proxy, tunnel client, status page |
| `internal_net` | LAN-only | Local dashboards, media, and monitoring | Grafana, Prometheus, File Browser, Media Server |

**Rule:** communication between networks is explicitly defined — never assumed.

---

## External / Hybrid Links

### WireGuard (VPN link)
Point-to-point encrypted tunnel between edge node and home node.

| Side | Host | Role | Address | Purpose |
|------|------|------|----------|----------|
| VPS | Edge node | Public gateway | `10.8.0.1` | Hosts game proxy, forwards traffic |
| Home | Core node | Private backend | `10.8.0.2` | Hosts isolated backend service |

- Encrypted UDP tunnel carrying all application traffic  
- No other ports exposed publicly  
- Firewall allows only minimal inbound traffic (`SSH`, `VPN`, and one game port)  

---

## Example Packet Flows

### Game Connection Flow
```

Client (Internet)
↓ TCP connection to public port
Edge Node — Proxy Service
↓ WireGuard tunnel (UDP)
↓ 10.8.0.1 → 10.8.0.2
Home Node — Backend Container
↓ bound to 10.8.0.2:<port>
↓ firewall chain: ACCEPT 10.8.0.1 → DROP others

```

**Security layers**
- Edge UFW: allows only essential ports  
- WireGuard: encrypts all traffic between nodes  
- Backend UFW: allows only VPN subnet  
- Container firewall (DOCKER-USER): explicit ACCEPT/DROP rules  
- Application whitelist enforced

---

### Web Service Flow
```

Internet
↓ HTTPS (443)
Cloudflare-style Edge
↓ Secure Tunnel → Home Node (no open ports)
Tunnel Client Container (public_net)
↓ HTTP (80)
Reverse Proxy (public_net)
↓ hostname routing
Service Container (public_net or internal_net)

```

---

## Example Port Mapping

| Service | Host Port | Container Port | Network | Exposed |
|----------|------------|----------------|----------|----------|
| Reverse Proxy | 80 (local) | 80 | public_net | via encrypted tunnel |
| Monitoring UI | 3000 | 3000 | internal_net | LAN only |
| Metrics Collector | 9090 | 9090 | internal_net | LAN only |
| Media Server | 8096 | 8096 | internal_net | LAN only |
| File Browser | 8080 | 80 | internal_net | LAN only |
| Game Server | — | 25565 | mc_net | via WireGuard only |

---

## Security Summary

- **All web ingress** routed exclusively through an encrypted tunnel and reverse proxy  
- **WireGuard VPN** is the only bridge between edge and home nodes  
- **UFW + Fail2Ban** active on both nodes (default-deny, anti-brute-force)  
- **No Docker bridge exposure** — containers communicate only on private networks  
- **SSH key authentication only**; no password logins  
- **Persistent DOCKER-USER rules** enforce inter-network restrictions  

---

