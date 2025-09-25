# Folder Structure 

**Tresor uses two main physical disks:**
- **SSD 480GB** → system, containers, configs, performance-critical volumes  
- **HDD 8TB**   → media, backups, large persistent data

***

## SSD – `/mnt/ssd/`  
> Used for fast-access data: container configs, Minecraft runtime, automation tools
```
/mnt/ssd/
├── containers/#Docker data
│        #Container configs (persistent)
├── configs/
│   ├── jellyfin/
│   ├── filebrowser/
│   ├── syncthing/
│   ├── kuma/#stateless, logs optional
│   ├── mc-server/ #ops, whitelist, logs
│   ├── mc-frontend/ #app settings, cache
│   ├── cf-tunnel/ #cf config +cert
│   ├── traefik/ #Dyn config, TLS certs
│   ├── grafana/ #Dashb, SQLite DB
│   ├── prometheus/ #rules, data dir
│   └── landing-site/                       │             #Static site: devops/photo
│
├── mc-world/#mc world data (active)
│   ├── world/#Region data, player data
│   ├── logs/
│   └── eula.txt
│
├──metrics/
│   ├── prometheus/
│   └── grafana/
│
├── ansible/ #Ansible roles, pb, .inv
└── scripts/ #Admin/maintenance scripts (restart, backup)

```

⸻

### HDD – `/mnt/hdd/data/`  
>used for bulk data, back-ups and write-heavy long-term folders
```
/mnt/hdd/data/
├── media/ #jellyfin content (RO mount)
│   ├── filme/ #1080p movies
│   ├── seriale/ #1080p shows
│   └── music/ #Music library
│
├── photos/
│   ├── raw/#RAW photos (Synced-legion)
│   └── jpg/# (Jellyfin + FileBrowser)
│
├── shared/#General LAN dropzone (RW)
│
└── backups/#Manual + automated backups
    ├── mc/  #Zipped backups of
    │        #/mnt/ssd/mc-world
    ├── joplin/ #MD exports
    ├── ansible/ #Git repo for backup
    └── raw-photos/
```



---

## Ownership & Permissions (Host-level)

| Path                            | Owner     | Group        | Mode | Notes                                     |
|----------------------------------|-----------|--------------|------|-------------------------------------------|
| `/mnt/hdd/data/media/*`          | root      | mediausers   | 775  | RW: Syncthing, FileBrowser — RO: Jellyfin (`:ro`) |
| `/mnt/hdd/data/photos/raw`       | root      | mediausers   | 770  | RW: Syncthing only                        |
| `/mnt/hdd/data/photos/jpg`       | root      | mediausers   | 775  | RW: FileBrowser — RO: Jellyfin           |
| `/mnt/hdd/data/shared`           | root      | mediausers   | 775  | RW: FileBrowser + Syncthing              |
| `/mnt/ssd/mc-world/`             | root      | admin        | 770  | Minecraft server world and runtime files |
| `/mnt/ssd/configs/*`             | root      | per-service  | 770  | Isolated per container                   |
| `/mnt/hdd/data/backups/*`        | root      | admin        | 770  | Containers can't access backups          |
| `/mnt/ssd/ansible/`              | radu      | radu         | 700  | Personal repo + scripts                  |

---

## Notes
- SSD hosts all fast-access services and live world/config volumes  
- HDD stores bulk data and write-heavy long-term folders  
- Minecraft runs entirely from SSD — only backups go to HDD  
- Jellyfin uses `:ro` mounts to prevent media modification  
- FileBrowser + Syncthing handle all media/file manipulation  
- No container shares config folders with others — strict isolation  
- Stateless services (MC Frontend, Landing Site, Uptime Kuma) are rebuilt from Ansible and don’t require backups  
