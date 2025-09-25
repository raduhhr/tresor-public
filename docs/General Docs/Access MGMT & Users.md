# Users & Access MGMT

Modular 4-user model for automation, security, and minimal manual intervention. Built around the "no-touch" philosophy — with fallback access if needed.

* * *

```
               ┌────────────┐
               │   root     │
               │ (holds all │
               │  power)    │
               └────┬───────┘
                    ▲
   ┌────────────┐   │   ┌────────────┐
   │  ansible   │───┘   │   admin    │
   │ (automation)│       │(manual ops)│
   │ limited use│       │ full sudo  │
   └────┬───────┘       └────┬───────┘
        │                    │
    (via sudo)           (via sudo -i or full sudo)
        │                    │
   ┌────▼─────┐         ┌────▼─────┐
   │  runs    │         │  escalates│
   │ limited  │         │ to root   │
   │ cmds     │         │ interactively│
   └──────────┘         └──────────────┘

           [Access is requested upward, privilege flows downward]


   ┌────────────────────────────────────────────┐
   │                 radu                       │
   │   (main user, no sudo, no escalation)      │
   │   uses shell, logs etc., but no privilege  │
   └────────────────────────────────────────────┘
```

* * *

### Privilege Flow

```text
radu     → no sudo
ansible  → sudo(limited&defined)→ root  [automated only]
admin    → sudo (full)        → root  [manual]
root     → never logged into directly
```

* * *

# Users:

## 🧑‍💻 `radu`

Main personal user

- **Sudo:**  No
- **Used for:**
    - Editing files, viewing logs
    - Manual file sync (e.g. photo folders)
    - Basic CLI use, local scripts
- **Login:** Yes (SSH + local)
- **Notes:** Cannot make system changes. No sudo access by design. Used only when inspection or debugging is needed.
- **Frequency of use:** Frequent (default shell access)
- **Ansible Role:** None

* * *

## `ansible`

Automation-only user

- **Sudo:** *(automated, limited scope)* → `root`
- **Used for:**
    - Running Ansible playbooks
    - Provisioning, installing packages, managing containers
- **Login:** Yes (SSH key only, no password)
- **Shell:** Planned: `rbash` or restricted shell
- **Sudo Scope:** Later Limited via `/etc/sudoers.d/ansible`
    - Only allowed to run specific commands (e.g. `apt`, `docker`, `systemctl`)
- **Frequency of use:** Frequent (but indirect — only used by automation)

* * *

## `admin`

Fallback maintenance user.   
Provisioned via an on-demand playbook and is disabled/removed after use

- **Sudo:** ✅ *(manual, full access)* → `root`
- **Used for:**
    - Emergency access
    - Recovering broken services if Ansible fails
    - Restarting daemons, inspecting logs, fixing volumes
- **Login:** Yes (SSH key or local)
- **Shell:** Full Bash
- **Sudo Scope:** Full access (may use `sudo -i` for root shell)
- **Frequency of use:** Rare (break-glass role only)

* * *

## `root`

System superuser (not directly used)

- **Sudo:** —
- **Used for:** Nothing directly
- **Login:** ❌ Disabled (no SSH, no login shell)
- **Access:** Only via `sudo` from `admin` or `ansible`
- **Frequency of use:** Never (accessed only via escalation)

* * *

## Groups

Linux groups used for permission-based access control in Tresor. All shared folders and container volumes are owned by `root:<group>` and set with `chmod 770` or 775 depending on access needs.

* * *

### Groups

| Group Name | Purpose | Members | Used In |
| --- | --- | --- | --- |
| `mediausers` | Shared access to photos, media, and shared volumes | `radu`, Jellyfin, FileBrowser, Syncthing | `/mnt/data/media`, `/mnt/data/photos`, `/mnt/data/shared` |
| `containers_rw` | Optional — RW access to shared container data (configs, staging folders) | Jellyfin, FileBrowser, Syncthing | `/mnt/data/configs/*`, optional |
| `docker` | System group for Docker socket (⚠ used *only* by Portainer or Ansible) | `root`, `admin`, optionally `ansible` | `/var/run/docker.sock` |

#### Group Explanations

- `mediausers`  
    Main data access group. Used for anything involving files that Jellyfin or FileBrowser may need. Access managed via group membership and host folder permissions.
    
- `containers_rw`  
    Optional group for containers that share read/write access to staging/config folders. Only created if containers like Syncthing, Jellyfin, or Kuma need to share mounts beyond `mediausers`.
    
- `docker`  
    System default group created when Docker is installed.  
    **Important security note:**
    
    - Do **not** add `radu` to this group.
    - Only add `admin` and/or `ansible` if needed for operational tasks.
    - Having access to the Docker socket is equivalent to full root access.

* * *

### Permissions Practice

All shared folders:

```bash
chown -R root:mediausers /mnt/data/photos
chmod -R 770 /mnt/data/photos
```