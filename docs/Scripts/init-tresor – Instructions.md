# Init-Tresor — Bootstrap Instructions 

Minimal, idempotent bootstrap that prepares a host for Ansible:

- creates `ansible` user with **NOPASSWD sudo**
    
- installs minimal deps (sudo, python3, python3-apt, rsync, openssh-server)
    
- enables **SSH key-only** auth, disables password/keyboard-interactive
    
- optional `AllowUsers` restriction (default: `ansible radu` while transitioning)
    

> Targets: **tresor (prod)** and **tresor-vm (QA)**

* * *

## ✅ Prerequisites

**On Legion (workstation):**

- SSH keypair: `~/.ssh/id_ed25519_tresor` (+ `.pub`)
    
- Ansible repo at `~/Desktop/tresor/ansible` (inventory already has `prod` and `qa`)
    
- The bootstrap script on Legion: `~/Desktop/tresor/scripts/init-tresor.sh`
    

**On target (fresh Debian 12):**

- User: `radu` (sudoer)
    
- SSH server enabled
    
- IPs known:
    
    - `tresor` (prod): `192.168.0.42`
        
    - `tresor-vm` (qa): `192.168.122.100`
        

* * *

## 📦 Copy the script to the target

### Option A — VM (over SSH)

```bash
scp ~/Desktop/tresor/scripts/init-tresor.sh radu@192.168.122.100:/tmp/
```

### Option B — PROD (over SSH)

```bash
scp ~/Desktop/tresor/scripts/init-tresor.sh radu@192.168.0.42:/tmp/
```

> (Offline/USB is fine too; just land the file at `/tmp/init-tresor.sh`.)

* * *

## ⚡ Run the bootstrap (remote one-liner; CRLF/BOM safe; force **bash**)

### **QA (tresor-vm)**

**Recommended (inject your current pubkey dynamically):**

```bash
PUBKEY="$(cat ~/.ssh/id_ed25519_tresor.pub)"
ssh -tt radu@192.168.122.100 " \
  sudo sed -i 's/\r$//' /tmp/init-tresor.sh && \
  sudo sed -i '1s/^\xEF\xBB\xBF//' /tmp/init-tresor.sh && \
  sudo chmod +x /tmp/init-tresor.sh && \
  sudo -H env \
    ANSIBLE_PUBKEY='$PUBKEY' \
    SET_HOSTNAME='tresor-vm' \
    ALLOW_USERS='ansible radu' \
    bash /tmp/init-tresor.sh \
"
```

### **PROD (tresor)**

```bash
PUBKEY="$(cat ~/.ssh/id_ed25519_tresor.pub)"
ssh -tt radu@192.168.0.42 " \
  sudo sed -i 's/\r$//' /tmp/init-tresor.sh && \
  sudo sed -i '1s/^\xEF\xBB\xBF//' /tmp/init-tresor.sh && \
  sudo chmod +x /tmp/init-tresor.sh && \
  sudo -H env \
    ANSIBLE_PUBKEY='$PUBKEY' \
    SET_HOSTNAME='tresor' \
    ALLOW_USERS='ansible radu' \
    bash /tmp/init-tresor.sh \
"
```

**You will be prompted twice:**

1.  `radu@<ip>'s password:` → SSH password for `radu` on that host
    
2.  `[sudo] password for radu:` → sudo password for `radu` on that host
    

After completion:

- `ansible` exists, **NOPASSWD sudo**
    
- SSH **password auth disabled**
    
- `AllowUsers ansible radu` set (you can later tighten to `ansible` only)
    

> Note: SSH will be reloaded; your session may briefly close. That’s normal.

* * *

## 🔍 Verify from Legion

```bash
# QA
ssh -i ~/.ssh/id_ed25519_tresor ansible@192.168.122.100 'whoami && hostname'
ssh -i ~/.ssh/id_ed25519_tresor ansible@192.168.122.100 'sudo -n true && echo OK'

# PROD
ssh -i ~/.ssh/id_ed25519_tresor ansible@192.168.0.42 'whoami && hostname'
ssh -i ~/.ssh/id_ed25519_tresor ansible@192.168.0.42 'sudo -n true && echo OK'
```

**Ansible pings**

```bash
cd ~/Desktop/tresor/ansible
ansible -i inventory/hosts.ini qa   -m ping
ansible -i inventory/hosts.ini prod -m ping
```

Expected:

- `whoami` prints `ansible`, hostnames `tresor-vm` / `tresor`
    
- `OK` without a sudo prompt
    
- Ansible `ping: pong`
    

&nbsp;

* * *

## 🧰 Troubleshooting

- **`set: Illegal option -o pipefail`**  
    The script ran under `/bin/sh` (dash). Always call it as `bash /tmp/init-tresor.sh` (see one-liner).
    
- **`init-tresor.sh: command not found` on line 1**  
    Missing shebang or UTF-8 BOM at start. We already strip BOM and CRLF and execute with bash in the one-liner:
    
    - `sed -i '1s/^\xEF\xBB\xBF//'` removes BOM
        
    - `sed -i 's/\r$//'` removes CRLF
        
    - `bash /tmp/init-tresor.sh` forces bash
        
- **`Permission denied (publickey)` after run**  
    Use the correct private key `~/.ssh/id_ed25519_tresor` and make sure your pubkey line exists in `/home/ansible/.ssh/authorized_keys` with strict perms:
    
    ```bash
    sudo chown -R ansible:ansible /home/ansible/.ssh
    sudo chmod 700 /home/ansible/.ssh
    sudo chmod 600 /home/ansible/.ssh/authorized_keys
    ```
    
- **Still prompting for sudo password as `ansible`**  
    Check `/etc/sudoers.d/99-ansible` exists and validates:
    
    ```bash
    sudo visudo -q -c
    sudo cat /etc/sudoers.d/99-ansible   # should contain: ansible ALL=(ALL) NOPASSWD:ALL
    ```
    
- **Want to re-run safely?**  
    It’s idempotent for the critical bits (user, keys, sudo, drop-in). Re-running is safe.
    

* * *

## 🧭 Summary

- **How to run**: *copy to `/tmp` → run remote one-liner that strips CRLF/BOM and calls `bash` with env vars*
    
- **What you get**: `ansible` user, key-only SSH, NOPASSWD sudo, password auth off
    
- **Next**: run `qa-fixes.yml` (locales + tighten SSH), then `setup-base.yml`, `setup-docker.yml`, `setup-networks.yml`.
    

&nbsp;