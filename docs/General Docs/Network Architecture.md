
---
## **Networking Architecture**

* `mc_net`: fully isolated, Minecraft server only
* `public_net`: internet-facing services via Traefik + Cloudflare Tunnel
* `internal_net`: LAN-only access

> Communication between services is only defined, never assumed.
---
##  **Network/Service mapping**

### `mc_net`
* **MC Server**
---

### `public_net`
* **Traefik** – reverse proxy
* **Cloudflare Tunnel** – secure tunnel for public exposure
* **MC Frontend** – whitelist + auth UI
* **Uptime Kuma** – public status page
* **Landing site** – `/devops` & `/photo` (CV + gallery)
---

### `internal_net`

* **Jellyfin** – LAN-only media server
* **Portainer** – Docker UI
* **Grafana** – monitoring dashboard
* **Prometheus** – metrics collector
* **Syncthing** – file sync engine
* **File Browser** – file explorer UI
---

##  **Domain & Access**

* Current Domain: `example.com`
* Example Subdomains:

  * `mc.example.com`
  * `media.example.com`
  * `grafana.example.com`
---
