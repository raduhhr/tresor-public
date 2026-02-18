# Tresor, K3s, Terraform, VLANs

## Current State
- Archer A8 router (stock firmware) → single ethernet cable → Tresor (1 node, 15+ services, Docker Compose, 5 isolated networks)
- Hetzner VPS with WireGuard tunnel proxying external traffic into Tresor
- Full Ansible automation (~15-20 roles), getting unwieldy
- Cloud footprint: Hetzner VPS, Cloudflare DNS, AWS SES — all managed manually via UI

---

## Phase 1 — Terraform (do this first, any time)

**Goal:** Codify existing cloud infrastructure as source of truth and DR artifact.

**What to cover:**
- Hetzner VPS (server, SSH key, firewall rules)
- Cloudflare DNS records and zones
- AWS SES verified identities
- Quiz app VPS (separate Terraform project/workspace)

**Why now:** If Hetzner dies tomorrow, you currently have to remember everything manually. With Terraform it's `terraform apply` and Ansible handles the rest. Also small surface area — ~150-200 lines HCL total for your current footprint. Easy win before the infra grows.

**Key concepts to learn as you go:**
- Providers (hcloud, cloudflare)
- Resources, variables, outputs
- Remote state backend (Terraform Cloud free tier or Hetzner Object Storage)
- `terraform plan` before every `terraform apply`

**Quiz app specifically:** Vertical scaling becomes `terraform apply -var="server_type=cx42"`. No need to wire it into CI/CD yet — runbook for now, automation later if it becomes annoying.

---

## Phase 2 — Second Node + K3s

**Goal:** Move from single-node Docker Compose to a proper multi-node cluster.

**Steps:**
1. Get a second node (mini PC or repurposed hardware)
2. Provision both nodes with Ansible (existing roles + new k3s role)
3. Bootstrap K3s — existing Tresor node as control plane, new node as worker
4. Start migrating services from Docker Compose to K3s manifests gradually

**CNI choice:**
- Default Flannel is fine to start
- Add Calico when you actually need NetworkPolicy (namespace isolation, service-to-service rules)
- Cilium is interesting later for observability but heavier

**What K3s gives you:**
- Real container orchestration experience that maps directly to your CELUM/AKS work
- Ingress controller (Traefik ships with K3s by default)
- Namespace-based logical isolation
- Portfolio item you can actually talk about

**Ansible + Terraform split at this stage:**
- Terraform provisions nodes if cloud (Hetzner), Ansible configures everything
- For physical homelab nodes Ansible stays king (no API to provision bare metal)
- Roles get split: base config stays in Ansible, infra state moves to Terraform

---

## Phase 3 — VLANs + Managed Switch (after Phase 2)

**Goal:** Proper L2 network segmentation once you have multiple nodes worth isolating.

**Why wait:** With one node there's nothing to segment. VLANs make sense when you have nodes with different trust levels and actual inter-node traffic to control.

**Hardware needed:**
- Flash OpenWrt on Archer A8 (free, supported) — enables proper 802.1Q inter-VLAN routing
- TP-Link TL-SG108E (~120-150 lei new from eMAG) — 8 port easy smart managed switch, web UI, does the job
- Cisco SG300-08 if you find one on OLX for <200 lei — better CLI experience but not required

**VLAN layout (rough):**

| VLAN | Purpose |
|------|---------|
| VLAN 10 | Trusted LAN (laptop, etc.) |
| VLAN 20 | Server nodes (K3s cluster) |
| VLAN 30 | Management (SSH, out-of-band) |

**Router note:** OpenWrt on A8 is sufficient. OPNsense on a dedicated mini PC is the natural next upgrade if you want better visibility/logging — but that's optional and later.

---

## Overall Timeline

```
Now          → Terraform for existing cloud infra (Hetzner, Cloudflare, SES)
Soon         → Second node → K3s on two nodes
After K3s    → Managed switch → OpenWrt → VLANs
~2 years     → Job change, by which point: K3s running, Terraform fluent,
                Ansible + Terraform split clean, real multi-node networking experience
```

---

## Key Principles
- **Don't overengineer ahead of the problem** — VLANs before a second node is correct but not necessary
- **Terraform = infrastructure documentation that also executes** — even if you never destroy/recreate, it's auditable and reproducible
- **Ansible stays for config, Terraform for provisioning** — they're complementary not competing
- **K3s not K8s** — 90% of the real experience, none of the operational overhead at this scale
- **Real infra > tutorial sandboxes** — stakes are real, learning sticks better