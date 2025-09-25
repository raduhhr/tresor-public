### Public-facing (`public_net`)

- **Traefik** — reverse proxy for web apps (TLS, rate limit, headers)
    
- **Cloudflare Tunnel** — exposure for HTTP(S) apps only (no MC over CF)
    
- **MC Control Panel (JS)** — Node.js app (Express + JS frontend) to auth/whitelist & start/stop MC
    
- **Uptime Kuma** — public status page
    
- **Landing site** — `/devops` & `/photo` (CV + gallery)
    
- **Velocity (Minecraft Proxy)** — TCP proxy for MC; runs on `25565`, **port-forwarded** from router → Velocity. Bridges players → backend MC server
    

&nbsp;

### Internal-only (`internal_net`)

- **Portainer** — Docker UI (admin only)
    
- **Grafana** — monitoring dashboard
    
- **Prometheus** — metrics collector
    
- **Jellyfin** — LAN-only (VLC client)
    
- **Syncthing** — file sync (RAW/JPEG)
    
- **File Browser** — file explorer UI  
    <br/>
    

&nbsp;

### Isolated (`mc_net`)

- **MC Server** — on-demand, whitelist-only, **behind Velocity** (no direct public exposure).  
    <br/>

&nbsp;

### Runtime/intents

- **24/7:** Traefik, Cloudflare Tunnel, MC frontend (JS), Velocity, Uptime Kuma, Landing, Prometheus, Portainer
    
- **On-Demand:** MC Server, Grafana, Jellyfin, Syncthing, File Browser, MC has a public cpanel accessible for my friends, while all services on internal_net will be managed by me with portanier/ansible playbooks.
    

&nbsp;

**Notes**

- **Velocity container attaches to both** `public_net` **and** `mc_net`**.**
    
- **MC Server attaches only to** `mc_net`**.**
    
- **Backend MC server authenticates via Velocity modern-forwarding secret.**
    
- **UFW allows** `25565/tcp` **from WAN → host (Velocity).**
    
- All other public exposure is HTTP(S) via Cloudflare Tunnel + Traefik.
    
- Each service installs its required packages only at deployment (not in base).
    

&nbsp;