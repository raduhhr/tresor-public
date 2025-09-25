
# Overview: Tresor – Self-Hosted, Modular, Secure Homelab

Tresor is a fully self-hosted, modular, and automated homelab infrastructure built for personal use, university thesis, and DevOps development. It is designed around security, extensibility, and minimal manual maintenance.

* * *

## **Hardware Specs**

- **CPU:** Intel i7-6700K (4c/8t, iGPU)
- **RAM:** 32GB DDR4 2133MHz
- **Storage:**
  - **SSD Kingston 480GB** – system, containers, logic
  - **WD Purple Pro 8TB** – media, backups, photo storage
- **Motherboard:** MSI H110M PRO-D
- **Networking:** Wired LAN (no Wi-Fi), behind router with DHCP + reserved static IP `192.168.0.42`

* * *

## **Core Principles**

- **No-touch:** only OS and SSH set up manually, everything else done via Ansible
- **Everything as Code:** infrastructure & deployments are declarative with playbooks
- **Modular Design:** each component is isolated in its own Ansible role
- **Security-first:** Cloudflare Tunnel, UFW, Fail2Ban, rootless Docker
- **Reproducible:** Can be redeployed identically on any system

* * *

## **Networking Architecture**

- `mc_net`: fully isolated, Minecraft server only
- `public_net`: internet-facing services via Traefik + Cloudflare Tunnel
- `internal_net`: LAN-only access (Jellyfin, Portainer, Grafana, etc.)

> Communication between services is explicitly defined, never assumed.

* * *

## **Core Services**

| Service | Description | Exposed? | Network |
| --- | --- | --- | --- |
| **Traefik** | Reverse proxy for all web services | ✅ | `public_net` |
| **Cloudflare Tunnel** | Secure tunnel for public exposure | ✅ | — |
| **MC Server** | On-demand server, cracked allowed | ✅ | `mc_net` |
| **MC Frontend** | Auth + whitelist UI to start server | ✅ | `public_net` |
| **Portainer** | Docker UI (admin only) | ❌ | `internal_net` |
| **Grafana** | Monitoring dashboard | ❌ | `internal_net` |
| **Uptime Kuma** | Public status page | ✅ | `public_net` |
| **Prometheus** | Metrics collector | ❌ | `internal_net` |
| **Jellyfin** | Media server (LAN-only, VLC as client) | ❌ | `internal_net` |
| **Landing site** | /devops & /photo (CV + gallery) | ✅ | `public_net` |
| **Syncthing** | Continuous sync for personal files (RAWs, JPEGs) | ❌ | `internal_net` |
| **File Browser** | Web UI for exploring & managing files | ❌ | `internal_net` |
| **Photoprism** | AI-powered photo viewer with RAW & album support | ❌ | `internal_net` |

* * *

## **Security Stack**

- **Cloudflare Tunnel:** no open ports publicly
- **Turnstile:** anti-bot for MC login UI
- **Rate Limiting:** via Traefik middleware
- **Fail2Ban:** brute-force protection (SSH + exposed ports)
- **UFW:** default deny, allow only what is needed
- **Rootless Docker:** most containers run as non-root

* * *

## **Users & Access**

- `radu`: main user, no root
- `ansible`: restricted SSH automation user
* * *

## **Ansible Automation**

Planned Playbooks:

- `setup-base.yml`: apt packages, SSH config, users, firewall, fail2ban
- `setup-docker.yml`: Docker + rootless config
- `setup-networks.yml`: create mc_net, internal_net, public_net
- `deploy-traefik.yml`
- `deploy-cloudflare.yml`
- `deploy-minecraft.yml`
- `deploy-mc-frontend.yml`
- `deploy-jellyfin.yml`
- `deploy-monitoring.yml`
- `deploy-landing-site.yml`
- `deploy-syncthing.yml`
- `deploy-filebrowser.yml`
- `deploy-photoprism.yml`

* * *

## **Domain & Access**

- Current Domain: `example.com`
- Future Pattern: `*.tresor.xyz`
- Example Subdomains:
  - `mc.example.com`
  - `media.example.com`
  - `grafana.example.com`

* * *

## **Documentation & Process**

- **Joplin:** local + exportable documentation
- **Trello:** task management
- **GitHub (Private):**
  - All Ansible roles
  - Shell/Python scripts
  - Config files (sanitized)
- **Thesis:** this project is the foundation of the bachelor's thesis

* * *

## **Future Expansion Plans**

- CI/CD using GitHub Actions > Ansible
- Secrets Management with SOPS or Vault
- GitOps via Gitea or Forgejo
- Optional migration to K3s (lightweight Kubernetes)
- Hosting university projects (PHP, C#, etc.)
- External backup on USB HDD
- Jellyfin media sharing for trusted users

* * *

## **Current Status:**

`Both vm and prod respond to ansible pings and minimal bootstrapped, ready for Ansible playbooks and roles.`

`Ongoing: setup-base.yml playbook before docker deploy.`