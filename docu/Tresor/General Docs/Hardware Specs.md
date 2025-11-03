* * *

## Host ***local-node*** hardware specs

**CPU:** Intel i7-6700K (4c/8t, iGPU)

**RAM:** 32GB DDR4 2133MHz Sk Hynix

**Storage:**

- **SSD Kingston 480GB** – Os, containers, logic
- **WD Purple Pro 8TB** – media, backups, photo storage

**Motherboard:** MSI H110M PRO-D

**Networking:** Wired LAN (no Wi-Fi), behind router with DHCP + reserved static IP: `192.0.2.10`

&nbsp;

* * *

## VPS *edge-node* hardware specs

Hosts the **Velocity proxy** for Minecraft, acts as the **WireGuard server (192.0.2.10)**, and exposes **port 25565/tcp** publicly.

**Provider:** Hetzner Cloud 
**Plan:** **CX23** (fsn1-dc14, Germany – Falkenstein) 
**Network Zone:** `eu-central`

| Component | Specification |
| --- | --- |
| **vCPU** | 2 vCPU (shared, AMD EPYC / Intel Xeon) |
| **RAM** | 4 GB DDR4 |
| **Storage** | 40 GB NVMe SSD |
| **Bandwidth** | 20 TB / month (unmetered inbound) |
| **Public IP** | `192.0.2.10` |
| **IPv6** | `2a01:4f8:c013:62ff::/64` |
| **Average Price** | €3.62 / month |
| **Firewall** | Managed via Ansible (`ufw` + Fail2Ban) |
| **Backups** | Optional (disabled for now, off-site rsync planned) |