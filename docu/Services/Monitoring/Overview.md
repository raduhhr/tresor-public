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

## Overview

| Component | Role | Network | Access |
|------------|------|----------|--------|
| **Prometheus** | Metrics collector | `internal_net` | `http://internal-node:9090` |
| **Grafana** | Visualization dashboard | `internal_net` | `http://internal-node:3000` |
| **Node Exporter** | Host metrics | Host → `internal_net` | Pulled by Prometheus |
| **cAdvisor** | Docker metrics | Container → `internal_net` | Pulled by Prometheus |
| **Uptime Kuma** | Public uptime badge | `public_net` | Routed via Cloudflare Tunnel + Traefik |

---

## Runtime Profile

| Setting | Value |
|----------|--------|
| Deployment type | Docker containers (Ansible-managed) |
| Prometheus port | `9090` (LAN only) |
| Grafana port | `3000` (LAN only) |
| Exporter ports | Node: `9100`, cAdvisor: `8080` |
| Retention | 15 days (local Prometheus volume) |
| Data path | `/mnt/ssd/configs/prometheus` |
| Dashboard path | `/mnt/ssd/configs/grafana` |
| Backups | `/mnt/data/backups/monitoring/` |

---

## Components & Roles

### `roles/prometheus`
- Deploys Prometheus (`prom/prometheus:latest`)
- Attaches only to `internal_net`
- Templates: `/mnt/ssd/configs/prometheus/prometheus.yml`
- Example scrape config:
  ```yaml
  scrape_configs:
    - job_name: prometheus
      static_configs: [{ targets: ["prometheus:9090"] }]
    - job_name: node
      static_configs: [{ targets: ["node-exporter:9100"] }]
    - job_name: cadvisor
      static_configs: [{ targets: ["cadvisor:8080"] }]

* Host port `9090` restricted to LAN subnet via iptables
* Health verification:

  * `/api/v1/status/runtimeinfo`
  * `/metrics`

**Gotcha:**
Docker’s internal DNS can cache old container IPs.
If exporters redeploy, run:

```bash
docker network disconnect internal_net <container> && \
docker network connect internal_net <container>
```

---

### `roles/grafana`

* Deploys Grafana (`grafana/grafana:latest`) on `internal_net`
* Environment variables:

  ```yaml
  GF_SECURITY_ADMIN_USER: admin
  GF_SECURITY_ADMIN_PASSWORD: "{{ vault_grafana_admin_pass }}"
  GF_SERVER_ROOT_URL: "http://internal-node:3000"
  GF_INSTALL_PLUGINS: "grafana-piechart-panel"
  ```
* Datasource auto-provisioned via `datasource.yml.j2`:

  ```yaml
  apiVersion: 1
  datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus:9090
      access: proxy
      isDefault: true
  ```
* LAN-only (no Traefik routing)
* Config and dashboards persist under `/mnt/ssd/configs/grafana/`

**Gotcha:**
If dashboards load empty after reboot:

* Ensure correct UID/GID ownership (`1000:1000`)
* Validate bind path for provisioning (`GF_PATHS_PROVISIONING`)

---

### `cAdvisor`

* Containerized (`gcr.io/cadvisor/cadvisor:latest`)
* Exposes container-level CPU, memory, and network stats
* Attached only to `internal_net`; no external ports
* Mounts:

  * `/var/run/docker.sock` (read-only)
  * `/` (read-only)

**Gotcha:**
Fails silently if `/var/lib/docker` isn’t mounted read-only — verify role mounts.

---

### `Node Exporter`

* Host-level metrics via `prom/node-exporter:latest`
* Exposes on port `9100`
* Allowed only from LAN via UFW (`192.0.2.0/24` or equivalent)
* Provides CPU, RAM, I/O, and filesystem metrics

---

### `Uptime Kuma`

* Deployed on `public_net` behind Traefik + Cloudflare Tunnel
* Example public route: `https://status.example.com`
* Monitors only external-facing services (e.g., proxy uptime)

---

## Security Model

* **Pull-only metrics** — no remote writes or auth bypass
* **No public exposure** for Prometheus/Grafana (LAN subnet only)
* **Firewall enforced:**

  * DOCKER-USER chain restricts `9090` and `3000` to LAN
* **Grafana admin password** stored in Ansible Vault
* **cAdvisor/Node Exporter** are non-authenticated but protected via LAN ACLs
* **Zero outbound telemetry** — fully local observability stack

---

## Maintenance Commands

| Task                        | Command                                                       |
| --------------------------- | ------------------------------------------------------------- |
| Restart monitoring stack    | `ansible-playbook playbooks/prometheus/deploy.yml`            |
| Check Prometheus health     | `curl -s http://internal-node:9090/-/healthy`                 |
| List Grafana dashboards     | `docker exec -it grafana ls /var/lib/grafana/dashboards`      |
| Cleanup old Prometheus data | `docker exec prometheus rm -rf /prometheus/chunks_head`       |
| Refresh Grafana dashboards  | `ansible-playbook playbooks/grafana/deploy.yml --tags reload` |

---

## Troubleshooting

| Issue                                | Cause                          | Fix                                    |
| ------------------------------------ | ------------------------------ | -------------------------------------- |
| Slow Prometheus UI                   | Long retention / large dataset | Lower retention or prune data          |
| Grafana “Bad Gateway”                | Start order                    | Ensure Prometheus is up before Grafana |
| Uptime Kuma false negatives          | DNS latency                    | Use IPs instead of hostnames           |
| CPU spikes                           | Frequent cAdvisor scrapes      | Increase scrape interval to 30s        |
| “Permission denied” in Node Exporter | Host protection                | Add `--path.procfs=/proc` flag         |

---

## Notes

* Monitoring is **LAN-first** — no external telemetry or cloud agents
* **cAdvisor + Node Exporter** together cover Docker and host metrics
* Grafana dashboards can be version-controlled (e.g., `tresor-dashboards/` subfolder)
* Stack is fully redeployable — Prometheus and Grafana auto-discover exporters

---
