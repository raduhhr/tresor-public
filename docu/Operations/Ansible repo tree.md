
```bash
project-folder-root/
├── ansible.cfg
├── inventory/
│   ├── group_vars/
│   │   ├── all/
│   │   │   └── main.yml
│   │   ├── prod/
│   │   │   ├── grafana.yml
│   │   │   ├── main.yml
│   │   │   ├── mc.yml
│   │   │   ├── prometheus.yml
│   │   │   └── vault.yml   [REDACTED]
│   │   ├── qa/
│   │   │   ├── main.yml
│   │   │   ├── mc.yml
│   │   │   └── vault.yml   [REDACTED]
│   │   └── vps/
│   │       ├── main.yml
│   │       └── vault.yml   [REDACTED]
│   ├── hosts.ini
│   └── host_vars/
│       └── edge-node.yml
│
├── playbooks/
│   ├── cloudflared/
│   ├── filebrowser/
│   ├── grafana/
│   ├── infra/              # base system setup (Docker, networks, etc.)
│   ├── jellyfin/
│   ├── motd/
│   ├── paper/              # Minecraft backend (Paper)
│   ├── prometheus/
│   ├── traefik/
│   ├── uptime-kuma/
│   └── vps/                # VPS automation (base, WireGuard, Velocity)
│
├── requirements.yml
│
├── roles/
│   ├── base/
│   ├── cloudflared/
│   ├── docker/
│   ├── filebrowser/
│   ├── grafana/
│   ├── jellyfin/
│   ├── motd/
│   ├── networks/
│   ├── paper/
│   ├── prometheus/
│   ├── traefik/
│   ├── uptime-kuma/
│   ├── velocity/
│   ├── wireguard-client/
│   └── wireguard-server/
│
└── vaults/
    ├── prod.vault     [ENCRYPTED]
    ├── qa.vault       [ENCRYPTED]
    └── vps.vault      [ENCRYPTED]

 110 directories, ~160 files
```


