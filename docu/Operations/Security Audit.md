
Below is a sanitized, shareable version. I removed/neutralized: hostnames, provider name, exact IPs/subnets, WireGuard addressing, repo paths, Ansible variable names, precise counters/byte volumes, and any details that materially improve an attacker’s targeting. I kept the technical story, severity, and the remediation patterns.

---

## Security audit — 19 Feb 2026

### 🔒 Infrastructure Security Audit & Hardening — February 19, 2026

**Performed by:** Radu
**Scope:** Port exposure audit across a home node and an edge VPS
**Trigger:** Routine infrastructure review
**Duration:** ~1 hour
**Result:** 7 findings identified; 6 remediated in-session; 1 pending (low risk)

---

## Executive Summary

A review of Docker port bindings found multiple services intended to be **LAN-only** were instead bound to **all host interfaces**, making them reachable from an **overlay/VPN-connected edge host**. This exposure was amplified by an overly broad firewall allow rule (larger CIDR than intended) in the Docker forwarding path.

In a credible threat model where the edge VPS is compromised, the attacker could have reached internal observability and file-management services and used them for rapid recon and escalation. The remediation focused on **restricting bind addresses**, **removing unnecessary host port publications**, and **tightening the firewall allow scope**. External verification from the edge host confirmed the affected LAN-only services are no longer reachable.

---

## Findings

### 🔴 F-01: LAN-only services bound to all interfaces (CRITICAL)

**Affected (examples):** monitoring UI, metrics endpoint, file management UI (RW to a data mount), media server, offline content server.

**Root cause:** Docker `published_ports` were bound to `0.0.0.0` rather than a LAN interface address. Because the VPN/overlay interface is also a valid host interface, these services became reachable from the edge host across the tunnel.

**Impact:** A compromise of the edge host could enable:

* **Recon** via metrics/monitoring (topology, container naming, resource patterns).
* **Credential reuse / weak auth exposure** via dashboards/admin UIs.
* **Direct data access** via file-management RW access to shared storage.
* **Lateral movement** facilitated by service discovery and internal endpoints.

**Remediation:** Rebound affected services to a **LAN-only bind address** and removed host publication where not needed.

**Verification:**

* **Before (from edge host):** LAN-only services reachable via tunnel.
* **After (from edge host):** LAN-only services blocked/unreachable.

---

### 🔴 F-02: Docker forwarding allow rule used an overly broad CIDR (HIGH)

**Root cause:** Firewall rule allowed a much larger private subnet than intended (order-of-magnitude more source IPs).

**Impact:** Increased attack surface and reduced assurance that “LAN-only” actually means “LAN-only,” especially in misrouting, bridging, or source-spoofing-adjacent scenarios.

**Remediation:** Tightened the rule to the **actual LAN subnet size**.

**Verification:** Rule counters dropped to expected levels consistent with real LAN traffic.

---

### 🟡 F-03: Host-published Node Exporter port unnecessary (MEDIUM)

**Root cause:** Metrics exporter was published on a host port despite being scraped over an internal Docker network.

**Impact:** Unnecessary exposure of host metrics endpoint.

**Remediation:** Removed host port publication; scrape via internal network/Docker DNS only.

---

### 🟡 F-04: Host-published cAdvisor port unnecessary (MEDIUM)

**Root cause:** Container metrics endpoint was published on a host port; also created a host-port conflict with another service.

**Impact:** Unnecessary exposure + operational risk from port collisions.

**Remediation:** Removed host port publication; scrape via internal network only.

---

### 🟡 F-05: Inventory/playbook variable precedence caused fixes to be bypassed (PROCESS)

**Root cause:** Higher-precedence variables (inventory and/or inline task values) overrode corrected role defaults; one playbook hardcoded an unsafe bind address.

**Impact:** Initial remediation attempts had no effect until the full precedence chain was audited.

**Remediation:** Updated overriding variables and removed hardcoding; ensured roles consistently consume bind-address variables.

**Lesson:** Variable precedence can defeat security defaults; audit **role defaults → inventory vars → playbook vars → inline task values**.

---

### 🟡 F-06: Edge HTTP service undocumented (DOCUMENTATION)

**Root cause:** Edge host had an intentional HTTP service listening, but documentation claimed no such service existed.

**Impact:** No direct security impact, but increases audit friction and risk of incorrect assumptions during incident response.

**Remediation:** Added documentation of the edge HTTP → tunnel/overlay → internal service path and the rationale for using it.

---

### ℹ️ F-07: UFW tasks fail on node without UFW installed (INFO)

**Root cause:** Roles invoked UFW modules without checking whether UFW exists; the node uses nftables/iptables directly.

**Impact:** No security impact; deploy playbooks fail late/noisily after containers are already running.

**Remediation (pending):** Add a guard to only run UFW tasks when UFW is present (pattern already used elsewhere).

---

## Final State

### Port Binding Matrix (post-hardening)

* Internal services: **LAN-only bind address** ✅
* One service: **overlay/VPN-only** (expected, via edge proxy) ✅
* Local-only component: **localhost-only** ✅
* Exporters/metrics: **no host ports** ✅
* Public exposure: only the intended edge entrypoints ✅

### Docker forwarding firewall chain (post-hardening)

* Allow: LAN subnet only ✅
* Allow: inter-container / internal bridges as needed ✅
* Default: fall through to standard forwarding policy ✅

### External Verification (from edge host)

* Previously reachable LAN-only ports: **now blocked** ✅
* Expected overlay/VPN-only service: **still reachable** ✅

---

## Files/Changes (generalized)

* Updated role defaults to introduce and enforce **bind address variables**
* Wired Docker container tasks to use those bind addresses
* Added container recreation where required to apply port binding changes
* Removed unnecessary host port publications for internal-only exporters
* Tightened Docker forwarding allow rule CIDR
* Fixed documentation and corrected an OS/version naming mismatch in docs
* Identified a separate config-generation task producing invalid output (technical debt)

---

## Remaining Items (non-blocking)

* Add UFW presence guard to roles (low)
* Document that host-network services bypass Docker forwarding chain (low)
* Avoid flushing Docker forwarding chain on every run; centralize rule ownership (medium)
* Remove duplicated inline container logic in playbooks; use roles consistently (low)
* Fix/remove invalid config-generation task that can cause container crash loops (medium)

---

**Audit performed:** February 19, 2026 (EET)
**Verification:** internal audit script + external probe from edge host

---

If you want a “public-facing” version (e.g., to share externally), I can further remove service names (Grafana/Prometheus/Jellyfin/etc.) and keep them as categories (“monitoring UI”, “metrics API”, “media service”), which reduces fingerprinting risk even more.
