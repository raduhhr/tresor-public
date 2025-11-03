
# Deployment Index — Tresor Homelab

Exact sequence for deploying the entire Tresor infrastructure, from a bare Debian installation to full Ansible automation and service rollout.

From **Step 2 onward**, all configuration changes are applied exclusively via **Ansible** (no manual edits).

---

## 0. Static IP Assignment

Initial one-time steps performed before Debian installation to ensure reproducible setup.

**Boot and IP Setup**

1. Boot the system from a Debian 12 USB stick.  
2. Select **Graphical Install**.  
3. Connect Ethernet when prompted.  
4. Allow the installer to auto-configure networking via DHCP.  
5. The system will receive a temporary IP.  
6. Pause the installation at this point.

**Static IP Reservation (on the router)**

1. Open the router’s administration page.  
2. Locate the device by MAC address in the DHCP client list.  
3. Reserve the IP `192.0.2.10` *(example address, outside DHCP pool)*.  
4. Save changes and reboot or replug the Ethernet cable to confirm the lease.

---

## 1. Debian 12 Installation and VM Setup

**Debian 12 (netinst ISO)**  
- Manual partitioning:  
  - SSD → `/`, EFI, `/mnt/ssd`  
  - HDD → `/mnt/data`  
- User: `mainuser` (sudo enabled)  
- Root login disabled  
- Only “SSH server” and “standard system utilities” selected  

Result: clean headless Debian installation ready for Ansible bootstrap.

**See:** [Debian 12 Installation Guide](1_Debian_12_Install.md)

---

### 1.1 Virtual Machine Setup (`tresor-vm`)
Reproducible Debian VM sandbox for QA testing and dry-runs.

**See:** [VM Debian Setup (tresor-vm)](1_1_VM_Setup.md)

---

### 1.2 VPS Setup (`tresor-vps`)
Edge node running WireGuard and Velocity Minecraft proxy.  
No Docker — all services managed directly via systemd.

Playbooks:  
`playbooks/vps/setup-base.yml`, `setup-wireguard.yml`, `setup-velocity.yml`

**See:** [VPS Setup (tresor-vps)](1_2_VPS_Setup.md)

---

## 2. Initial Bootstrap Script

**Purpose:** Prepare the node for Ansible automation.

Script: `init-tresor.sh`

**Usage**
```bash
scp scripts/init-tresor.sh user@<host>:/tmp/
sudo -E ANSIBLE_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
SET_HOSTNAME="tresor" ALLOW_USERS="ansible mainuser" \
bash /tmp/init-tresor.sh
````

**Script actions**

* Creates `ansible` user with passwordless sudo
* Installs minimal dependencies (`sudo`, `python3`, `rsync`, `openssh-server`)
* Hardens SSH (disables root login and password auth)

**Verification**

```bash
ssh ansible@<host>
sudo -n true && echo "OK"
ansible -m ping all
```

**See:** [init-tresor.sh](scripts/init-tresor.sh)

---

## 3. Deploy the Base System

Playbook → `playbooks/infra/setup-base.yml`

**Tasks**

* Install core packages (sudo, curl, fail2ban, ufw, etc.)
* Configure SSH (`AllowUsers`, no root login)
* Set timezone and locale
* Apply sysctl tweaks from `99-tresor.conf.sysctl.j2`
* Deploy custom `/etc/motd`

**Verification**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-base.yml
```

---

## 4. Deploy Docker

Playbook → `playbooks/infra/setup-docker.yml`

**Tasks**

* Install Docker Engine (rootless)
* Configure `daemon.json` and cgroups
* Enable access for `ansible` user
* Validate Docker installation

**Verification**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-docker.yml
```

---

## 5. Create Docker Networks

Playbook → `playbooks/infra/setup-networks.yml`

**Networks Created**

* `public_net` → Cloudflare + Traefik
* `lan_pub` → LAN web access
* `internal_net` → monitoring and media stack
* `mc_pub` → WireGuard bridge
* `mc_net` → isolated PaperMC backend

**Verification**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-networks.yml
```

---

## 6. Deploy WireGuard

Playbooks:

* Home: `infra/setup-wireguard.yml` (client `10.8.0.2`)
* VPS: `vps/setup-wireguard.yml` (server `10.8.0.1`)

**Purpose**
Establish a secure tunnel for Minecraft traffic only; no other routes traverse WireGuard.

**Verification**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-wireguard.yml
```

---

## 7. Deploy MOTD

Playbook → `playbooks/motd/deploy.yml`
Displays host metadata (role, Ansible run time) at login.

---

## 8. Deploy Cloudflare Tunnel

Playbook → `playbooks/cloudflared/deploy.yml`

**Tasks**

* Install `cloudflared` container
* Authenticate using token from Vault
* Register `public_net` routes for HTTPS

**Verification**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/cloudflared/status.yml
```

---

## 9. Deploy Traefik Reverse Proxy

Playbook → `playbooks/traefik/deploy.yml`

**Tasks**

* Deploy Traefik container on `public_net`
* Mount dynamic configs from templates
* Enable Cloudflare → Traefik → Uptime Kuma routing
* Apply middlewares (rate-limit, headers, Turnstile)

---

## 10. Deploy Public-Facing Services

Playbook → `playbooks/uptime-kuma/deploy.yml`
Deploys Uptime Kuma (public status page) on `public_net`.

---

## 11. Deploy Internal Services

**Playbooks**

```bash
ansible-playbook playbooks/filebrowser/deploy.yml
ansible-playbook playbooks/jellyfin/deploy.yml
```

Services attach to `internal_net`.
Access via LAN, for example: `http://192.0.2.10:<port>`

---

## 12. Deploy Minecraft Backend

Playbook → `playbooks/paper/deploy.yml`

Traffic path:
Velocity → WireGuard → `mc_pub` → PaperMC

**Backup Playbook**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/paper/backup.yml
```

---

## 13. Deploy Monitoring Stack

Order-sensitive sequence:

```bash
ansible-playbook playbooks/prometheus/deploy.yml
ansible-playbook playbooks/grafana/deploy.yml
```

The Prometheus playbook also deploys Node Exporter and cAdvisor.

---

## 14. Final Infrastructure Check

Playbook → `playbooks/infra/status-all.yml`

Run:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/infra/status-all.yml --limit tresor
```

Generates a summary report of container and service status across all nodes.

---




