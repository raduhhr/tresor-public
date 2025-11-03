&nbsp;

# Tresor — Container Access URLs (LAN)

| Service | Description | Port | URL |
| --- | --- | --- | --- |
| **Grafana** | Monitoring dashboard | `3000` | [http://192.0.2.10:3000](http://192.0.2.10:3000/) |
| **Prometheus** | Metrics collector | `9090` | [http://192.0.2.10:9090](http://192.0.2.10:9090/) |
| **FileBrowser** | File management UI | `8080` | [http://192.0.2.10:8080](http://192.0.2.10:8080/) |
| **Jellyfin** | Media server (LAN only) | `8096` | [http://192.0.2.10:8096](http://192.0.2.10:8096/) |
| **Uptime Kuma** | Public status page (runs on public_net, via cf-tunnel->traefik) | `3001` | [https://mc-status.example.com](https://mc-status.example.com/status/local-node%5B%5D%28http://192.0.2.10:3001/%29 "https://mc-status.example.com/status/local-node%5B%5D(http://192.0.2.10:3001/)") |
| **Paper (Minecraft)** | Game server (not HTTP, WG-only) | `25565` | *`192.0.2.10:25565`* |

* * *

### Notes

- All listed services except Kuma and Paper are **LAN-only** (bound to `mc_pub`or `lan_pub`).
 
- **Uptime Kuma** is accessible publicly via Cloudflare → Traefik
 
- **Traefik dashboard** is not exposed
 
- **PaperMC** is reachable only via WireGuard through the VPS proxy.
 

* * *

&nbsp;