# Tresor – Self-Hosted, Modular, Secure Homelab

Tresor is a fully self-hosted, modular, and automated homelab infrastructure built for personal use, university thesis, and DevOps development.  
It features complete Docker network separation, a dedicated public VPS edge node, and a local VM mirror (VMM).  
Everything from provisioning to deployment is handled entirely through Ansible, with full LAN monitoring via Grafana and Prometheus.  
It is designed around security, extensibility, and minimal manual maintenance.

> This is the sanitized, fully reproducible public mirror of my self-hosted homelab.  
> All credentials, IPs, and domains have been replaced or encrypted.

## Core Principles
- **No-touch:** only OS and SSH set up manually; everything else via Ansible  
- **Everything as Code:** infrastructure and deployments are declarative  
- **Modular Design:** each component isolated in its own Ansible role  
- **Security-first:** Cloudflare Tunnel, Fail2Ban, Docker network separation  
- **Reproducible:** can be redeployed identically on any system  

## Networking Architecture
- `mc_net`: isolated, Minecraft backend only  
- `mc_pub`: WireGuard bridge (VPS ↔ backend)  
- `public_net`: internet-facing services via Traefik + Cloudflare Tunnel  
- `internal_net`: LAN-only access (Grafana, Jellyfin, Prometheus, etc.)  
- `lan_pub`: LAN broadcast bridge so internal services are visible locally  

<pre>
        _____________________Internet                             
        |                       │	                     		        lan_pub (LAN bridge)
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

**Jellyfin libraries**
<img width="1812" height="900" alt="image" src="https://github.com/user-attachments/assets/44f53ac0-99c3-4398-9551-f9ad258843a5" />

**Filebrowser tree**
<img width="2549" height="820" alt="image" src="https://github.com/user-attachments/assets/6826927f-c7e9-4102-83bb-834e35503d75" />



# Monitoring Stack — Prometheus, Grafana, cAdvisor, Node Exporter

All components operate **LAN-only** — no external exposure.  
Data flows one way: metrics are **pulled internally**; there are **no WAN-bound pushes or telemetry**.

```

[Node Exporter]     [cAdvisor]
│                   │
└─────> Prometheus ◄┘
│
▼
Grafana

````

---
**Grafana Host dashboard**
<img width="2542" height="1212" alt="image" src="https://github.com/user-attachments/assets/25ae2361-3c91-4f04-890c-7434857cc337" />

**Grafana Containers dashboard**
<img width="2560" height="1267" alt="image" src="https://github.com/user-attachments/assets/3093b781-33d3-4939-8d51-69f46bf0873b" />


| Component | Role | Network | Access |
|------------|------|----------|--------|
| **Prometheus** | Metrics collector | `internal_net` | `http://internal-node:9090` |
| **Grafana** | Visualization dashboard | `internal_net` | `http://internal-node:3000` |
| **Node Exporter** | Host metrics | Host → `internal_net` | Pulled by Prometheus |
| **cAdvisor** | Docker metrics | Container → `internal_net` | Pulled by Prometheus |
| **Uptime Kuma** | Public uptime badge | `public_net` | Routed via Cloudflare Tunnel + Traefik |

## Security Stack
- Cloudflare Tunnel → no open ports publicly  
- Rate limiting via Traefik middleware  
- Fail2Ban for brute-force protection  
- Ansible Vault → no tokens in Git  

## Users & Access
- `mainuser`: primary account, no root login  
- `ansible`: automation user (key-only, limited)  

## Documentation & Process
- Joplin for documentation  
- Trello for task tracking  
- GitHub (Public, sanitized) for roles, scripts, configs  
- The foundation for the bachelor’s thesis  

## Status: Fully deployed and continuously monitored.  
All components provisioned through Ansible, containerized under Docker, and secured via Cloudflare Tunnel + WireGuard.  
System uptime >99.9% since deployment.  

**small status-all playbook output**
> Paper (MC server) is the only unhealthy service because it’s so locked down not even Docker’s health probe can reach it.
<img width="694" height="1299" alt="image" src="https://github.com/user-attachments/assets/3963ff02-ae2f-408f-adc9-622f4fe04b00" />



## Future Expansion
- Scheduled rsync backups  
- External USB HDD backup  
- CI/CD via GitHub Actions → Ansible  
- GitOps (Forgejo/Gitea)

---



