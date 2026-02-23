# Tresor – Self-Hosted, Modular, Secure Homelab

Tresor is a fully self-hosted, modular, and automated homelab infrastructure built for personal use, DevOps development, and as the foundation for a bachelor's thesis.  
It features complete Docker network separation, a dedicated Hetzner VPS edge node, WireGuard tunneling, and a local KVM sandbox.  
Everything from provisioning to deployment is handled entirely through Ansible (20 roles, 70+ playbooks), with full LAN monitoring via Grafana and Prometheus.  
Designed around security, extensibility, and minimal manual maintenance.

> This is the sanitized, fully reproducible public mirror of my self-hosted homelab.  
> All credentials, IPs, and domains have been replaced or encrypted via Ansible Vault.

## Core Principles
- **No-touch:** only OS and SSH set up manually; everything else via Ansible
- **Everything as Code:** infrastructure and deployments are fully declarative
- **Modular Design:** each component isolated in its own Ansible role
- **Security-first:** Cloudflare Tunnel, WireGuard, Fail2Ban, Docker network separation, LAN-only bind addresses
- **Reproducible:** can be redeployed identically on any system

## Infrastructure

Three hosts, three environments:

| Host | Environment | Description |
|------|-------------|-------------|
| **tresor** | prod | Home Docker host — runs all services, 192.168.0.0/24 LAN |
| **tresor-vm** | qa | KVM sandbox for testing roles before prod |
| **tresor-vps** | vps | Hetzner VPS — WireGuard server, Velocity MC proxy, nginx reverse proxy |

## Networking Architecture

Five isolated Docker networks enforce strict traffic boundaries:

| Network | CIDR | Purpose | Services |
|---------|------|---------|----------|
| `public_net` | 172.30.0.0/24 | Internet-facing via Cloudflare Tunnel + Traefik | Traefik, Cloudflared, Uptime Kuma |
| `internal_net` | 172.28.0.0/24 | LAN-only east–west traffic | Grafana, Prometheus, Jellyfin, FileBrowser, Kiwix |
| `mc_net` | 172.29.0.0/24 | Isolated Minecraft backend | PaperMC |
| `mc_pub` | 172.26.0.0/24 | WireGuard bridge (VPS ↔ MC backend) | PaperMC egress |
| `lan_pub` | 172.27.0.0/24 | LAN broadcast bridge | Internal services visible locally |

<pre>
        _____________________Internet                             
        |                       │                                    lan_pub (LAN bridge)
        |             Cloudflare Tunnel (HTTPS 443)                  ────────────────────
        |                       │                                            │
        |                       |                                            │
        |                    Traefik  (HTTP)                        internal_net (LAN-only)
        |                       │                                   ───────────────────────
        |                  public_net                                • Jellyfin        :8096
        |               (exposed via CF)                             • Jellyfin Music  :18096 (WG)
        |              ─────────────────                             • FileBrowser     :8080
        |              • Uptime Kuma                                 • Grafana         :3000
        |                                                            • Prometheus      :9090
        |                                                            • Kiwix           :8181
        |
Velocity MC Proxy-----------------------------------------|
──────────────────────────                                |
• Hetzner VPS (WireGuard Server 10.66.66.1)               |
• Public 25565 / UFW protected                            |
                                                          |
                                            mc_pub (WireGuard bridge)
                                            ─────────────────────────
                                            • bridge → mc_net (PaperMC)
                                                           │
                                                           ▼
                                                mc_net (isolated backend)
                                                ─────────────────────────
                                                • PaperMC (Docker)
                                                • whitelist-only, offline

  music.raduhhr.xyz → VPS nginx → WireGuard → Jellyfin Music (10.66.66.2:18096)
</pre>

## tresor-ctl

A Python cli control panel that auto-discovers services from the `playbooks/` directory structure.  
Provides a terminal dashboard for running lifecycle actions (deploy, start, stop, restart, status, backup, update, remove etc) against any service without memorizing playbook paths again.
<img width="1083" height="1355" alt="image" src="https://github.com/user-attachments/assets/434d41a1-8cf3-43b1-97b0-343eb611d751" />


## Core Services

| Service | Description | Exposed? | Network | Access |
|---------|-------------|----------|---------|--------|
| **Traefik** | Reverse proxy for all web services | ✅ | `public_net` | Via CF Tunnel |
| **Cloudflared** | Secure Cloudflare Tunnel ingress | ✅ | `public_net` | — |
| **Uptime Kuma** | Public MC status page | ✅ | `public_net` | mc-status.raduhhr.xyz |
| **PaperMC** | Minecraft server (offline-mode, whitelist) | ✅ | `mc_net` / `mc_pub` | VPS Velocity → WG |
| **Jellyfin Music** | Music-only Jellyfin, served via VPS | ✅ | `internal_net` | music.raduhhr.xyz (WG-bound) |
| **Grafana** | Monitoring dashboard | ❌ | `internal_net` | LAN :3000 |
| **Prometheus** | Metrics collector | ❌ | `internal_net` | LAN :9090 |
| **Node Exporter** | Host-level metrics | ❌ | `internal_net` | Pulled by Prometheus |
| **cAdvisor** | Docker container metrics | ❌ | `internal_net` | Pulled by Prometheus |
| **Jellyfin** | Media server (movies, shows, photos) | ❌ | `internal_net` | LAN :8096 |
| **FileBrowser** | Web UI for file management | ❌ | `internal_net` | LAN :8080 |
| **Kiwix** | Offline Wikipedia (110 GB ZIM) | ❌ | `internal_net` / `lan_pub` | LAN :8181 |

### Cron & Notification Bots

| Service | Description | Schedule |
|---------|-------------|----------|
| **steam-free-notifier** | Discord alerts for free Steam games | Cron-based |
| **bday-notifier** | Birthday reminder bot | Cron-based |

### VPS Services (systemd, not Docker)

| Service | Description |
|---------|-------------|
| **Velocity** | Minecraft proxy — accepts public :25565 and forwards to Tresor over WG |
| **nginx** | Reverse proxy for music.raduhhr.xyz → WG tunnel to Jellyfin Music |

## Monitoring Stack

All components operate **LAN-only** — no external exposure.  
Data flows one way: metrics are pulled internally; there are no WAN-bound pushes or telemetry.

```
[Node Exporter]     [cAdvisor]
       │                   │
       └─────> Prometheus ◄┘
                    │
                    ▼
                 Grafana
```

**Grafana Host dashboard**  
<img width="2542" height="1212" alt="image" src="https://github.com/user-attachments/assets/25ae2361-3c91-4f04-890c-7434857cc337" />

**Grafana Containers dashboard**  
<img width="2560" height="1267" alt="image" src="https://github.com/user-attachments/assets/3093b781-33d3-4939-8d51-69f46bf0873b" />

**Jellyfin libraries**  
<img width="1812" height="900" alt="image" src="https://github.com/user-attachments/assets/44f53ac0-99c3-4398-9551-f9ad258843a5" />

**FileBrowser tree**  
<img width="2549" height="820" alt="image" src="https://github.com/user-attachments/assets/6826927f-c7e9-4102-83bb-834e35503d75" />

## Ansible Automation

20 roles and 70+ playbooks with consistent conventions:

**Playbook lifecycle per service:** `deploy` · `remove` · `backup` · `start` · `stop` · `restart` · `status` · `update`

**Key conventions:**
- Config dirs: `/mnt/ssd/configs/<service>/`
- Backup dirs: `/mnt/data/files/Backups/<service>/`
- Backup naming: `<service>-backup-DDMMYYYY-HHMM.tar.gz` with 30-day automatic pruning
- Version pinning: centralized in `group_vars/prod/versions.yml` via `tresor_versions` dict — never hardcoded
- Secrets: Ansible Vault, never in Git
- Variable hierarchy: `ansible.cfg` → `group_vars/all` → `group_vars/{prod,qa,vps}` → `host_vars` → role defaults

```
roles/
├── base/              # System hardening, users, SSH, Fail2Ban, UFW
├── docker/            # Docker CE install + daemon config
├── networks/          # All 5 Docker networks
├── wireguard-client/  # WG client on tresor (10.66.66.2)
├── wireguard-server/  # WG server on VPS (10.66.66.1)
├── motd/              # Dynamic SSH welcome banner
├── traefik/           # Reverse proxy + TLS
├── cloudflared/       # Cloudflare Tunnel
├── grafana/           # Monitoring dashboard
├── prometheus/        # Metrics (+ node-exporter, cAdvisor)
├── jellyfin/          # Media server
├── jellyfin-music/    # Music-only instance (WG-bound)
├── filebrowser/       # File management UI
├── uptime-kuma/       # Status page
├── kiwix/             # Offline Wikipedia
├── paper/             # Minecraft server
├── velocity/          # MC proxy (VPS)
├── nginx-music/       # Music reverse proxy (VPS)
├── bday-notifier/     # Birthday bot (cron)
└── steam-free-notifier/ # Steam deals bot (cron)
```

## Security

- **Zero public ports on tresor** — all public traffic enters via Cloudflare Tunnel or WireGuard
- **Cloudflare Tunnel** → Traefik for HTTPS services, no open inbound ports
- **WireGuard** → encrypted tunnel between VPS (10.66.66.1) and tresor (10.66.66.2)
- **UFW** → default deny, allowlisted per-service with /24 CIDRs
- **Fail2Ban** → brute-force protection on SSH and exposed services
- **Docker bind addresses** → LAN services bind to 192.168.0.42 (not 0.0.0.0), preventing accidental WireGuard exposure
- **DOCKER-USER iptables** → tightened to /24 CIDR for LAN allowlisting
- **Node Exporter / cAdvisor** → no published host ports, internal_net only
- **Ansible Vault** → all secrets encrypted, zero tokens in Git

## Backup Strategy

Automated via Ansible playbooks with a consistent pattern across all stateful services:

1. Stop container
2. Archive config directory → `tar.gz` with timestamped filename
3. Start container
4. Log operation with ISO 8601 timestamp to `/var/log/<service>-backup.log`
5. Prune backups older than 30 days

A `backup-all.yml` infra playbook runs backups across all services sequentially.


## Users & Access
- `radu` / `mainuser`: primary account, no root login
- `ansible`: restricted SSH automation user (key-only)

## Documentation & Process
- **Joplin** for local documentation
- **Trello** for task tracking
- **GitHub (Public, sanitized)** for all roles, scripts, and configs

## Status

Fully deployed and continuously monitored.  
All components provisioned through Ansible, containerized under Docker, and secured via Cloudflare Tunnel + WireGuard.

**status-all playbook output**  
> Paper (MC server) is the only unhealthy service because it's so locked down not even Docker's health probe can reach it.

<img width="694" height="1299" alt="image" src="https://github.com/user-attachments/assets/3963ff02-ae2f-408f-adc9-622f4fe04b00" />

## Future Expansion
- K3s migration with Terraform provisioning
- Three-node architecture: control plane / public services / backup storage
- External USB HDD backup target
- CI/CD via GitHub Actions → Ansible
- GitOps via Forgejo or Gitea
