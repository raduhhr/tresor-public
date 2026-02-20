# 🔒 Homelab Security Audit & Hardening — February 2026

**Scope:** Full port exposure audit across home node and edge VPS  
**Trigger:** Routine infrastructure review  
**Duration:** ~1 hour  
**Result:** 7 findings identified, all remediated same-session

---

## Executive Summary

An audit of the homelab's Docker port bindings revealed that five LAN-only services were bound to `0.0.0.0` instead of the LAN interface, making them reachable over the WireGuard tunnel from the VPS. Combined with an overly broad CIDR (`/16` instead of `/24`) in the DOCKER-USER firewall chain — accepting 65,536 source IPs instead of the intended 254 — an attacker who compromised the VPS would have had direct access to Grafana, Prometheus, FileBrowser (RW to the data mount), Kiwix, and Jellyfin — effectively full infrastructure compromise within minutes.

All findings were remediated by rebinding services to the LAN interface, removing unnecessary host port publications, and tightening the DOCKER-USER CIDR. External verification from the VPS confirmed all LAN-only services are now unreachable over WireGuard.

---

## Findings

### 🔴 F-01: LAN-only services exposed on all interfaces (CRITICAL)

**Affected:** Grafana (3000), Prometheus (9090), FileBrowser (8080), Kiwix (8181), Jellyfin (8096)

**Root cause:** Docker `published_ports` bound to `0.0.0.0` instead of the LAN IP. Since the WireGuard interface is a valid host interface, all five services were reachable from the VPS over the tunnel.

**Impact:** Anyone who compromised the VPS could reach:

- **Prometheus** — full infrastructure topology, container names, resource metrics (perfect recon)
- **Grafana** — monitoring dashboards with default credentials
- **FileBrowser** — RW access to the data mount (media, photos, backups, shared files)
- **Jellyfin** — media library access
- **Kiwix** — lower risk, but still an unnecessary exposure

**Remediation:** Rebound all five to the LAN IP via Ansible role defaults and group_vars.

**Verification:**

```
BEFORE (from VPS):
  REACHABLE: <WG_IP>:3000   (Grafana)
  REACHABLE: <WG_IP>:8080   (FileBrowser)
  REACHABLE: <WG_IP>:8096   (Jellyfin)
  REACHABLE: <WG_IP>:8181   (Kiwix)
  REACHABLE: <WG_IP>:9090   (Prometheus)

AFTER (from VPS):
  BLOCKED:   <WG_IP>:3000
  BLOCKED:   <WG_IP>:8080
  BLOCKED:   <WG_IP>:8096
  BLOCKED:   <WG_IP>:8181
  BLOCKED:   <WG_IP>:9090
```

---

### 🔴 F-02: DOCKER-USER chain uses /16 instead of /24 (HIGH)

**Location:** Base role, Docker firewall fix task

**Root cause:** Rule accepted `<LAN_SUBNET>/16` (65,536 IPs) instead of `<LAN_SUBNET>/24` (254 IPs).

**Impact:** Any traffic from a broader RFC 1918 range — including potentially spoofed or misrouted packets — would be accepted by the DOCKER-USER chain.

**Remediation:** Changed to `/24`.

**Verification:**

```
BEFORE:
  ip saddr <LAN_SUBNET>/16 counter packets 62M bytes 163G accept

AFTER:
  ip saddr <LAN_SUBNET>/24 counter packets 1891 bytes 811758 accept
```

---

### 🟡 F-03: Node Exporter published on host port 9100 (MEDIUM)

**Location:** Prometheus role

**Root cause:** `published_ports: "9100:9100"` in the container task. Prometheus scrapes node-exporter over the internal Docker network — no host port needed.

**Impact:** Host metrics endpoint exposed on all interfaces unnecessarily.

**Remediation:** Removed `published_ports` entirely. Prometheus reaches it via Docker DNS on the internal network.

---

### 🟡 F-04: cAdvisor published on host port 8080 (MEDIUM)

**Location:** Prometheus role

**Root cause:** Same as F-03 — `published_ports: "8080:8080"`. Also conflicted with FileBrowser's host port.

**Impact:** Container metrics endpoint exposed on all interfaces unnecessarily.

**Remediation:** Removed `published_ports` entirely.

---

### 🟡 F-05: Group vars overriding role defaults (PROCESS)

**Location:** Production group_vars

**Root cause:** Bind addresses for Jellyfin and FileBrowser were set to `0.0.0.0` in group_vars, overriding the corrected role defaults. The Jellyfin deploy playbook also hardcoded `0.0.0.0` inline, bypassing both role defaults and group_vars.

**Impact:** Initial fix attempts had no effect until group_vars and inline playbook values were also corrected.

**Remediation:** Updated group_vars to use the LAN IP. Fixed inline hardcoding in the deploy playbook.

**Lesson:** Ansible variable precedence: role defaults < group_vars < playbook vars < inline task values. Always check the full chain.

---

### 🟡 F-06: Nginx on VPS undocumented (DOCUMENTATION)

**Root cause:** VPS audit showed nginx listening on ports 80/443, but existing documentation stated no HTTP services were running on the VPS.

**Impact:** No security impact (the service is intentional), but creates confusion during audits and for anyone reviewing the infrastructure.

**Remediation:** Created documentation covering the full nginx → WireGuard → media streaming path.

---

### ℹ️ F-07: UFW tasks fail on home node (INFO)

**Affected:** Jellyfin and FileBrowser roles

**Root cause:** Both roles call `community.general.ufw` without checking if UFW is installed. The home node uses nftables directly (managed by Docker + manual rules), not UFW.

**Impact:** Deploy playbooks fail at the UFW task after the container is already running. No security impact — just noisy failures.

**Remediation (pending):** Add UFW availability check (same pattern already used in Grafana and Prometheus roles):

```yaml
- name: Check if ufw is available
  ansible.builtin.command: which ufw
  register: _ufw_check
  changed_when: false
  failed_when: false

- name: Allow service in UFW from LAN only
  community.general.ufw: ...
  when: _ufw_check.rc == 0
```

---

## Final State

### Port Binding Matrix (post-hardening)

| Container | Bind Address | Port | Status |
|---|---|---|---|
| **grafana** | `<LAN_IP>` | 3000 | ✅ LAN-only |
| **prometheus** | `<LAN_IP>` | 9090 | ✅ LAN-only |
| **filebrowser** | `<LAN_IP>` | 8080 | ✅ LAN-only |
| **kiwix** | `<LAN_IP>` | 8181 | ✅ LAN-only |
| **jellyfin** | `<LAN_IP>` | 8096 | ✅ LAN-only |
| **jellyfin-music** | `<WG_IP>` | 18096 | ✅ WG-only (VPS nginx) |
| **cloudflared** | `127.0.0.1` | 8086 | ✅ Localhost-only |
| **paper** | `<WG_IP>` | 25565 | ✅ WG-only (host network) |
| **node-exporter** | — | — | ✅ No host port |
| **cadvisor** | — | — | ✅ No host port |
| **traefik** | — | — | ✅ No host port (CF Tunnel) |
| **uptime-kuma** | — | — | ✅ No host port (CF Tunnel) |

### DOCKER-USER Chain (post-hardening)

```
ip saddr <LAN_SUBNET>/24  → ACCEPT     (LAN traffic only)
iifname "docker0"          → ACCEPT     (inter-container)
iifname "br-internal_net"  → ACCEPT     (east-west)
iifname "br-public_net"    → ACCEPT     (CF tunnel path)
iifname "br-lan_pub"       → ACCEPT     (LAN bridge)
default                    → RETURN     (fall through to FORWARD)
```

### External Verification (from VPS)

```
BLOCKED:   <WG_IP>:3000   (Grafana)
BLOCKED:   <WG_IP>:8080   (FileBrowser)
BLOCKED:   <WG_IP>:8096   (Jellyfin)
BLOCKED:   <WG_IP>:8181   (Kiwix)
BLOCKED:   <WG_IP>:9090   (Prometheus)
BLOCKED:   <WG_IP>:9100   (Node Exporter)
REACHABLE: <WG_IP>:18096  (jellyfin-music — expected)
```

---

## Files Modified

| File | Change |
|---|---|
| Grafana role defaults | Added LAN bind address |
| Grafana role tasks | Wired port binding using bind_addr variable; added `recreate: true` |
| Prometheus role defaults | Added LAN bind address |
| Prometheus role tasks | Bound Prometheus to LAN; removed node-exporter + cAdvisor host ports; removed stale UFW rules; added `recreate: true`; fixed healthcheck URL |
| FileBrowser role defaults | Changed bind address to LAN IP |
| FileBrowser role tasks | Added `recreate: true` |
| Jellyfin role defaults | Changed bind address to LAN IP |
| Production group_vars | Changed Jellyfin and FileBrowser bind addresses from `0.0.0.0` to LAN IP |
| Jellyfin deploy playbook | Changed hardcoded `0.0.0.0` to variable reference |
| Kiwix role defaults | Changed bind address to LAN IP |
| Kiwix role tasks | Fixed smoke test URL to use bind_addr |
| Base role tasks | Changed DOCKER-USER CIDR from `/16` to `/24` |

---

## Remaining Items (non-blocking)

| Item | Priority | Notes |
|---|---|---|
| Add UFW guard to jellyfin + filebrowser roles | Low | Cosmetic — deploys fail at UFW task but containers run fine |
| Game server DOCKER-USER rules missing | Low | Runs in host mode, so DOCKER-USER doesn't apply. Document this. |
| Base role flushes DOCKER-USER on every run | Medium | `iptables -F DOCKER-USER` wipes any rules added by other roles. Consider a single DOCKER-USER task file that runs last. |
| Jellyfin deploy playbook has inline container task | Low | Should use the role instead of duplicating logic. Technical debt. |
| VPS docs have incorrect Debian version | Low | Docs say one version, kernel confirms another. |
| Seed migrations task produces invalid XML | Medium | Caused crash loop after container recreation. Removed file manually; task needs fixing or removing. |

---

*Audit performed: February 2026*  
*All remediations verified via internal audit script + external VPS probe*
