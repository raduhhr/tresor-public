# Overview: Tresor – Self-Hosted, Modular, Secure Homelab

Tresor is a fully self-hosted, modular, and automated homelab infrastructure built for personal use, university thesis, and DevOps development.  
It features complete Docker network separation, a dedicated public VPS edge node, and a local VM mirror (VMM).  
Everything from provisioning to deployment is handled entirely through Ansible, with full LAN monitoring via Grafana and Prometheus.  
It is designed around security, extensibility, and minimal manual maintenance.

## Core Principles
- **No-touch:** only OS and SSH set up manually; everything else via Ansible  
- **Everything as Code:** infrastructure and deployments are declarative  
- **Modular Design:** each component isolated in its own Ansible role  
- **Security-first:** Cloudflare Tunnel, UFW, Fail2Ban, Docker network separation  
- **Reproducible:** can be redeployed identically on any system  

## Networking Architecture
- `mc_net`: isolated, Minecraft backend only  
- `mc_pub`: WireGuard bridge (VPS ↔ backend)  
- `public_net`: internet-facing services via Traefik + Cloudflare Tunnel  
- `internal_net`: LAN-only access (Grafana, Jellyfin, Prometheus, etc.)  
- `lan_pub`: LAN broadcast bridge so internal services are visible locally  

<pre>
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
• Hetzner VPS (WireGuard Server 10.66.66.1)               |
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
</pre>

## Core Services
| Service | Description | Exposed? | Network |
|----------|--------------|----------|----------|
| Traefik | Reverse proxy for web services | ✅ | public_net |
| Cloudflare Tunnel | Secure public ingress | ✅ | — |
| Minecraft Server | On-demand offline-mode backend | ✅ | mc_net |
| Uptime Kuma | Public status page | ✅ | public_net |
| Landing Site | Personal CV + gallery | ✅ | public_net |
| Grafana | Monitoring dashboard | ❌ | internal_net |
| Prometheus | Metrics collector | ❌ | internal_net |
| Jellyfin | Media server (LAN-only) | ❌ | internal_net |
| File Browser | Web UI for file management | ❌ | internal_net |

## Security Stack
- Cloudflare Tunnel → no open ports publicly  
- Rate limiting via Traefik middleware  
- Fail2Ban for brute-force protection  
- UFW default-deny  
- Ansible Vault → no tokens in Git  

## Users & Access
- `mainuser`: primary account, no root login  
- `ansible`: automation user (key-only, limited)  

## Documentation & Process
- Joplin for documentation  
- Trello for task tracking  
- GitHub (Public, sanitized) for roles, scripts, configs  
- The foundation for the bachelor’s thesis  

## Future Expansion
- Scheduled rsync backups  
- External USB HDD backup  
- CI/CD via GitHub Actions → Ansible  
- GitOps (Forgejo/Gitea)

---

**Status:** Fully implemented, documented, and monitored.
