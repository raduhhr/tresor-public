
# Overview: Tresor – Self-Hosted, Modular, Secure Homelab

**Tresor** is a fully self-hosted, modular, and automated homelab infrastructure built for personal use, academic research, and DevOps development.  
It features complete Docker network isolation, a lightweight remote VPS edge node, and a local VM mirror for reproducible testing.  

Everything from provisioning to deployment is handled entirely via **Ansible**, with full LAN monitoring provided by **Grafana** and **Prometheus**.  
The system is designed around **security**, **extensibility**, and **minimal manual maintenance**.

---

## Core Principles

- **No-Touch Automation:** Only OS installation and SSH setup are manual; all else is automated via Ansible.  
- **Everything as Code:** Infrastructure, roles, and deployments are fully declarative.  
- **Modular Design:** Each component is isolated in its own Ansible role.  
- **Security-First:** All public exposure passes through encrypted tunnels; strict UFW and Fail2Ban enforcement.  
- **Reproducible:** The entire environment can be redeployed identically on any compatible host.

---

## Networking Architecture

| Network | Scope | Purpose | Example Services |
|----------|--------|----------|------------------|
| `mc_net` | Isolated | Backend game service | Game server container only |
| `mc_pub` | VPN bridge | Connects proxy (VPS) to internal backend | WireGuard interface only |
| `public_net` | Internet-facing | Public web ingress via tunnel + reverse proxy | Traefik, tunnel client, status page |
| `internal_net` | LAN-only | Dashboards and media | Grafana, Prometheus, Jellyfin, File Browser |
| `lan_pub` | LAN bridge | Local LAN broadcast for service discovery | Web UI access for internal services |

**Rule:** Communication between networks is explicitly defined — never assumed.

---


---

## Core Services

| Service | Description | Exposed? | Network |
|----------|--------------|----------|----------|
| Traefik | Reverse proxy and entrypoint for web services | ✅ | `public_net` |
| Cloudflare Tunnel | Secure encrypted ingress (no open ports) | ✅ | — |
| Status Page | Public uptime/status dashboard | ✅ | `public_net` |
| Landing Site | `/devops` and `/photo` — portfolio and gallery | ✅ | `public_net` |
| Grafana | Monitoring dashboards | ❌ | `internal_net` |
| Prometheus | Metrics collector | ❌ | `internal_net` |
| Jellyfin | Media streaming (LAN-only) | ❌ | `internal_net` |
| File Browser | File manager UI for shared data | ❌ | `internal_net` |
| Game Backend | Isolated backend service (VPN-only) | ✅ (via VPN) | `mc_net` |

---

## Security Stack

- **Cloudflare Tunnel** – eliminates public open ports  
- **Traefik Middleware** – rate limiting, secure headers  
- **UFW Firewall** – default deny, only required ports allowed  
- **Fail2Ban** – SSH and port brute-force protection  
- **Ansible Vault** – secrets encrypted, no plaintext tokens in repo  
- **Rootless Docker** – non-privileged containers wherever possible  

---

## Access Model

| User | Purpose | Privileges |
|-------|----------|-------------|
| `mainuser` | Personal user (no sudo) | View logs, interact with local services |
| `ansible` | Automation-only | Passwordless sudo, SSH key access only |
| `root` | System superuser | Disabled direct login, accessed via sudo |

---

## Documentation & Process

- **Knowledge Base:** structured Markdown documentation  
- **Task Management:** tracked via Trello or issue board  
- **Version Control:** all automation stored in private Git repository  
- **Scripts:** bootstrap, deployment, and verification utilities  
- **Academic Use:** foundation for a reproducible infrastructure thesis  

---

## Future Expansion Plans

- Scheduled configuration backups (`rsync`)  
- External backup via encrypted external drive  
- CI/CD integration with GitHub Actions → Ansible pipeline  
- GitOps workflow via Gitea or Forgejo  
- Optional lightweight Kubernetes (K3s) migration  

---

## Current Status

Fully implemented, automated, and monitored ,under active refinement.
All playbooks, network segmentation, and security layers verified in production and VM mirrors.  


