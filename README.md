# Tresor: Self-hosted homelab infrastructure: Docker, Ansible (22 roles, 135+ playbooks), WireGuard, Cloudflare Tunnel, Prometheus/Grafana

Tresor is a fully self-hosted, modular, and automated homelab infrastructure built for personal use and DevOps development.
It features complete Docker network separation, a dedicated Hetzner VPS edge node, WireGuard tunneling, and a local KVM sandbox.  

Everything from provisioning to deployment is handled entirely through Ansible (22 roles, 135+ playbooks), with full LAN monitoring via Grafana and Prometheus.  
Designed around security, extensibility, and minimal manual maintenance.


---

## Core Principles

- **No-touch:** only OS and SSH set up manually; everything else via Ansible
- **Everything as Code:** infrastructure and deployments are fully declarative
- **Modular Design:** each component isolated in its own Ansible role
- **Security-first:** Cloudflare Tunnel, WireGuard, Fail2Ban, Docker network separation, LAN-only bind addresses
- **Reproducible:** can be redeployed identically on any system

---

## Infrastructure

Three hosts, three environments:

| Host | Environment | Description |
|------|-------------|-------------|
| **tresor** | prod | Home Docker host — runs all services, 192.168.0.0/24 LAN |
| **tresor-vm** | qa | KVM sandbox for testing roles before prod |
| **tresor-vps** | vps | Hetzner VPS — WireGuard server, Velocity MC proxy, nginx reverse proxy |

---

## Ansible Automation

22 roles and 135+ playbooks with consistent conventions across every service.

**Playbook lifecycle per service:** `deploy` · `remove` · `backup` · `restore` · `backup-test` · `start` · `stop` · `restart` · `status` · `update`

**Key conventions:**
- Config dirs on SSD: `/mnt/ssd/configs/<service>/`
- Backup dirs: `/mnt/data/files/Backups/<service>/`
- Backup naming: `<service>-backup-DDMMYYYY-HHMM.tar.gz` with 30-day automatic pruning
- Version pinning: centralized in `group_vars/prod/versions.yml` via `tresor_versions` dict — never hardcoded in roles
- Secrets: Ansible Vault with per-environment identity labels (prod, qa, vps) — zero tokens in Git
- Variable hierarchy: `ansible.cfg` → `group_vars/all` → `group_vars/{prod,qa,vps}` → `host_vars` → role defaults

```
roles/
├── base/                  # System hardening, users, SSH, Fail2Ban, UFW, sysctl, unattended-upgrades
├── docker/                # Docker CE install + daemon config
├── networks/              # All 5 Docker networks
├── wireguard-client/      # WG client on tresor (10.66.66.2)
├── wireguard-server/      # WG server on VPS (10.66.66.1)
├── motd/                  # Dynamic SSH welcome banner
├── traefik/               # Reverse proxy + TLS + rate-limiting middleware
├── cloudflared/           # Cloudflare Tunnel
├── grafana/               # Monitoring dashboard
├── prometheus/            # Metrics (+ node-exporter, cAdvisor)
├── jellyfin/              # Media server (movies, shows, photos)
├── jellyfin-music/        # Music-only instance (WG-bound :18096)
├── filebrowser/           # Personal file management UI
├── filebrowser-public/    # Friends 1TB file drop (WG-bound :8082)
├── uptime-kuma/           # MC status page
├── kiwix/                 # Offline Wikipedia
├── paper/                 # Minecraft server
├── velocity/              # MC proxy (VPS, systemd)
├── nginx-music/           # Reverse proxy for music + cloud subdomains (VPS)
├── content-notifier/      # Discord alerts for new Jellyfin media
├── bday-notifier/         # Birthday bot (cron + Discord)
└── steam-free-notifier/   # Steam free game alerts (cron + Discord)
```
## tresor-ctl

A Python TUI control panel that auto-discovers services from the `playbooks/` directory structure.  
Provides a terminal dashboard for running lifecycle actions (deploy, start, stop, restart, status, backup, update, remove, etc.) against any service without memorizing playbook paths.

Built with Rich + Questionary + Paramiko for live SSH interaction.

<img width="1148" height="1312" alt="image" src="https://github.com/user-attachments/assets/c393777b-5330-4b8e-b4f7-0ae98c615661" />


---

## Networking Architecture

Five isolated Docker networks enforce strict traffic boundaries:

| Network | Purpose | Services |
|---------|---------|----------|
| `public_net` | Internet-facing via Cloudflare Tunnel + Traefik | Traefik, Cloudflared, Uptime Kuma |
| `internal_net` | LAN-only east–west traffic | Grafana, Prometheus, Jellyfin, FileBrowser, Kiwix |
| `mc_net` | Isolated Minecraft backend | PaperMC |
| `mc_pub` | WireGuard bridge (VPS ↔ MC backend) | PaperMC egress |
| `lan_pub` | LAN broadcast bridge | Internal services visible locally |

```
         _____________________ Internet
         |                       │                                  lan_pub (LAN bridge)
         |             Cloudflare Tunnel (443)                      ────────────────────
         |                       │                                          │
         |                    Traefik (HTTP)                       internal_net (LAN-only)
         |                       │                                 ───────────────────────
         |                  public_net                              • Jellyfin        :8096
         |               (exposed via CF)                           • Jellyfin Music  :18096 (WG)
         |              ─────────────────                           • FileBrowser     :8080
         |              • Uptime Kuma                               • FileBrowser Pub :8082 (WG)
         |                                                          • Grafana         :3000
         |                                                          • Prometheus      :9090
         |                                                          • Kiwix           :8181
         |
  Hetzner VPS (WireGuard Server)
  ──────────────────────────────
  • nginx: music.raduhhr.xyz  → WG → Jellyfin Music (:18096)
  • nginx: cloud.raduhhr.xyz  → WG → FileBrowser Pub (:8082)
  • Velocity MC proxy (:25565) → WG → PaperMC
         |
         |                                        mc_pub (WireGuard bridge)
  Velocity MC Proxy ─────────────────────────────────────────────────|
                                                                     │
                                                            mc_net (isolated backend)
                                                           ─────────────────────────
                                                            • PaperMC (Docker)
                                                            • whitelist-only, offline
```

---

## Services

### Docker Containers (tresor — prod)

| Service | Description | Exposed? | Network | Access |
|---------|-------------|----------|---------|--------|
| **Traefik** | Reverse proxy for all web services | Yes | `public_net` | Via Cloudflare Tunnel |
| **Cloudflared** | Secure Cloudflare Tunnel ingress | Yes | `public_net` | — |
| **Uptime Kuma** | Public MC status page | Yes | `public_net` | mc-status.raduhhr.xyz |
| **PaperMC** | Minecraft server (offline-mode, whitelist) | Yes | `mc_net` / `mc_pub` | VPS Velocity → WG |
| **Jellyfin Music** | Music-only Jellyfin instance | Yes | `internal_net` | music.raduhhr.xyz (VPS nginx → WG) |
| **FileBrowser Public** | 1 TB file drop for friends | Yes | `public_net` | cloud.raduhhr.xyz (VPS nginx → WG) |
| **Grafana** | Monitoring dashboard | No | `internal_net` | LAN :3000 |
| **Prometheus** | Metrics collector | No | `internal_net` | LAN :9090 |
| **Node Exporter** | Host-level metrics | No | `internal_net` | Pulled by Prometheus |
| **cAdvisor** | Docker container metrics | No | `internal_net` | Pulled by Prometheus |
| **Jellyfin** | Media server (movies, shows, photos) | No | `internal_net` | LAN :8096 |
| **FileBrowser** | Personal file management UI | No | `internal_net` | LAN :8080 |
| **Kiwix** | Offline Wikipedia (110 GB ZIM) | No | `internal_net` / `lan_pub` | LAN :8181 |

### Cron & Notification Bots (tresor — prod)

| Service | Description | Schedule |
|---------|-------------|----------|
| **content-notifier** | Discord alerts when new media lands in Jellyfin libraries | Cron |
| **steam-free-notifier** | Discord alerts for free Steam games | Cron |
| **bday-notifier** | Birthday reminder bot via Discord | Cron |

### VPS Services (systemd, not Docker)

| Service | Description |
|---------|-------------|
| **Velocity** | Minecraft proxy — accepts public :25565 and forwards to tresor over WG |
| **nginx** | Reverse proxy for music.raduhhr.xyz and cloud.raduhhr.xyz → WG tunnel |

---

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
<img width="2542" alt="Grafana Host dashboard" src="https://github.com/user-attachments/assets/25ae2361-3c91-4f04-890c-7434857cc337" />

**Grafana Containers dashboard**  
<img width="2560" alt="Grafana Containers dashboard" src="https://github.com/user-attachments/assets/3093b781-33d3-4939-8d51-69f46bf0873b" />

**Jellyfin libraries**  
<img width="1812" alt="Jellyfin libraries" src="https://github.com/user-attachments/assets/44f53ac0-99c3-4398-9551-f9ad258843a5" />

**FileBrowser tree**  
<img width="2549" alt="FileBrowser tree" src="https://github.com/user-attachments/assets/6826927f-c7e9-4102-83bb-834e35503d75" />

---

## Security

- **Zero public ports on tresor** — all public traffic enters via Cloudflare Tunnel or WireGuard
- **Cloudflare Tunnel** → Traefik for HTTPS services, no open inbound ports
- **WireGuard** → encrypted tunnel between VPS and tresor
- **UFW** → default deny, allowlisted per-service with /24 CIDRs
- **Fail2Ban** → brute-force protection on SSH and exposed services
- **Docker bind addresses** → LAN services bind to 192.168.0.42 (not 0.0.0.0), WG services bind to 10.66.66.2
- **DOCKER-USER iptables** → tightened to /24 CIDR for LAN allowlisting
- **Node Exporter / cAdvisor** → no published host ports, internal_net only
- **Ansible Vault** → per-environment encrypted secrets, zero tokens in Git
- **SSH hardening** → key-only auth, no root login, custom sshd config

---

## Backup Strategy

Automated via Ansible playbooks with a consistent pattern across all stateful services.

**Backup cycle:**

1. Stop container (ensures data consistency)
2. Archive config directory → `tar.gz` with timestamped filename
3. Start container
4. Log operation with ISO 8601 timestamp to `/var/log/<service>-backup.log`
5. Prune backups older than 30 days

A `backup-all.yml` infra playbook runs backups across all services sequentially.

**Restore playbooks** for every service follow a safe sequence: validate tarball → pre-restore safety snapshot → stop & remove container → wipe data directory → extract backup → fix ownership → redeploy via role. Each restore supports auto-picking the latest backup or targeting a specific snapshot via `-e backup_file=`.

**Backup verification** via `backup-test.yml` playbooks for critical stateful services (Paper, Grafana, Prometheus, Uptime Kuma, Jellyfin, Jellyfin Music). Each test runs the full lifecycle — fresh backup → fingerprint data (DB hashes, file counts) → destroy → restore → redeploy → compare fingerprints — proving backup integrity end-to-end.

---

## Users & Access

- `radu` / `mainuser`: primary account, no root login
- `ansible`: restricted SSH automation user (key-only, sudoers)

---

## Documentation & Process

- **Joplin** for local documentation
- **Trello** for task tracking
- **GitHub (Public, sanitized)** for all roles, scripts, and configs

---

## Status

Fully deployed and continuously monitored.  
All components provisioned through Ansible, containerized under Docker, and secured via Cloudflare Tunnel + WireGuard.  

**status-all playbook output**  

<img width="429" height="1308" alt="image" src="https://github.com/user-attachments/assets/e387d558-f2b6-4d3c-bae6-c1ea86d53550" />


---

## Future Expansion

- K3s migration with Terraform provisioning
- Three-node architecture: control plane / public services / backup storage
- Off-host rsync backups + external USB HDD target
- CI/CD via GitHub Actions → Ansible
- GitOps via Forgejo or Gitea
