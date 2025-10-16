
# Tresor — Self-Hosted, Modular, Secure Homelab (Public Snapshot)

**Tresor** is a fully self-hosted homelab built for security, reproducibility, and low manual maintenance.
This repo is the **public, sanitized snapshot** of the project: docs, Ansible skeleton, and deployment patterns (no secrets).

> **Highlights**
>
> * Everything as Code via Ansible (idempotent roles + playbooks)
> * Docker, UFW, Fail2Ban, Traefik, Cloudflare Tunnel
> * Strict network segmentation: `public_net`, `internal_net`, `mc_net`
> * Reproducible, modular, and well-documented

---

## Architecture (high-level)

```
        _____________________Internet
        |                     │
        |           Cloudflare Tunnel
        |                     │
        |                 Traefik
        |                     │
        |            ┌────────┴
        |            │                 
        |       public_net         internal_net
        |     (exposed via CF)     (LAN-only access)
        |   ─────────────────     ─────────────────
        |   • Landing site        • Jellyfin
        |   • MC Frontend         • Grafana + Prometheus
        |   • Status page         • Portainer
        |                         • File services
        |
Velocity Proxy------------------|
─────────────────               |                             
• Hetzner CX22 VPS          mc_net (isolated)
• Wireguard, UFW,          ─────────────────
                           • Minecraft Server
```

* **No public ports** opened on the router; public services go through **Cloudflare Tunnel** → **Traefik**.
* **Jellyfin / monitoring / admin UIs** are **LAN-only** on `internal_net`.
* **Minecraft** runs in its own **isolated** network `mc_net, port is not open to internet, only to wireguard on vps. 

---

## Repo Structure

```
.
├─ ansible/            # Playbooks, roles, inventories (examples only)
│  ├─ inventory/       # hosts.ini.example, group_vars examples
│  ├─ playbooks/       # setup-base.yml, deploy-*.yml, verify-*.yml
│  └─ roles/           # base/, docker/, traefik/, services/...
├─ docs/               # Project overview and service notes (public-safe)
├─ scripts/            # Helper scripts (no secrets)
├─ .gitignore          # Safety nets (no dumps/keys/logs)
└─ README.md
```

> **Note:** Real secrets, tokens, keys, and exact IPs/domains are **not** stored here.
> Examples use **TEST-NET** addresses like `192.0.2.42` and placeholder domains like `example.com`.

---

## Core Principles

* **No-touch**: only OS + SSH done manually; everything else via Ansible.
* **Modular**: each component is an Ansible role with clear inputs/outputs.
* **Security-first**: least privilege, rootless containers, rate limits, auth.
* **Reproducible**: one command redeploys the same state on fresh metal/VM.

---

---

## Networking Model (summary)

* `public_net`: internet-facing apps behind Traefik + Cloudflare Tunnel.
* `internal_net`: LAN-only; not attached to Traefik, East-West comms for my lan services. 
* `mc_net`: dedicated isolated network for the Minecraft server.

Communication between services is **explicitly defined**, never assumed.

---

## Security Posture

* **Cloudflare Tunnel**: zero open ports on WAN.
* **Traefik**: reverse proxy, rate limiting, middleware.
* **Turnstile/Auth**: for public UI (e.g., MC frontend).
* **UFW + Fail2Ban**: default-deny, brute-force protection.
* **Audit/Verify**: Ansible “verify” plays confirm final state.

---

## What’s Not In This Repo

* Secrets: API tokens, private keys, real domain names
* Exact LAN IPs and CIDRs (examples only)
* Private dumps/logs/state

---

## Roadmap

* CI/CD (GitHub Actions → Ansible)
* Secrets management via SOPS or Vault
* GitOps via Gitea/Forgejo
* Optional migration to K3s
* External USB HDD backup flow
* Expand public docs (service-by-service deep dives)

---

## Quick Start (local lab / QA)

> These steps assume a Debian-based host and Ansible installed on your control machine.

1. **Clone**:

```bash
git clone https://github.com/raduhhr/tresor-public.git
cd tresor-public/ansible
```

2. **Copy and edit inventory** (examples use )

```bash
cp inventory/hosts.ini.example inventory/hosts.ini
cp -r inventory/group_vars.example/* inventory/group_vars/
# edit hosts.ini and group_vars to match your lab (IPs, users, allowlists)
```

3. **Dry-run a base setup** (idempotent hardening, time sync, UFW, Fail2Ban):

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-base.yml --check
```

4. **Apply for real**:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-base.yml
```

5. **Install Docker and networks**:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-docker.yml
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml
```

6. **Deploy services** (examples):

```bash
ansible-playbook -i inventory/hosts.ini playbooks/services/deploy-traefik.yml
ansible-playbook -i inventory/hosts.ini playbooks/services/deploy-cloudflare.yml
ansible-playbook -i inventory/hosts.ini playbooks/services/deploy-monitoring.yml
ansible-playbook -i inventory/hosts.ini playbooks/services/deploy-jellyfin.yml
ansible-playbook -i inventory/hosts.ini playbooks/services/deploy-minecraft.yml
```

> Each service playbook contains its own **verify** tasks so you can prove state after convergence.

