
# Operations Manual — Ansible Quick Commands

A condensed reference for managing playbooks, containers, and encrypted secrets in the **Tresor** automation stack.  
All examples assume execution from the project root (e.g., `~/tresor/ansible`).

---

## 🔹 Deploy or Re-deploy a Playbook

### Run on a specific host group:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/paper/deploy.yml --limit prod
````

### Run on a specific host:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/paper/deploy.yml --limit home-node
```

### Run multiple roles sequentially:

```bash
ansible-playbook -i inventory/hosts.ini \
  playbooks/{traefik,cloudflared,prometheus,grafana}/deploy.yml --limit prod
```

### Dry-run (simulate without applying changes):

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --limit prod --check
```

### Verbose/debug mode:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml -vv
```

> Verbosity ranges from `-v` to `-vvvv` (highest detail-you don't want that trust me).

---

## 🔹 Start / Stop / Restart Containers or Services

### Stop containers:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/docker/stop.yml --limit home-node
```

### Start containers:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/docker/start.yml --limit home-node
```

### Restart containers:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/traefik/restart.yml --limit home-node
```

### Restart via ad-hoc command:

```bash
ansible home-node -i inventory/hosts.ini -m community.docker.docker_container \
  -a "name=traefik state=restarted"
```

---

## 🔹 Manage Encrypted Secrets (ansible-vault)

### Encrypt a new secret file:

```bash
ansible-vault encrypt group_vars/prod/vault.yml
```

### Edit an existing vault file:

```bash
ansible-vault edit group_vars/prod/vault.yml
```

### View contents (read-only):

```bash
ansible-vault view group_vars/prod/vault.yml
```

### Re-encrypt with a new password:

```bash
ansible-vault rekey group_vars/prod/vault.yml
```

### Use vault automatically (prompts for password):

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --ask-vault-pass
```

### Or use a password file (for CI/local automation):

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml \
  --vault-password-file ~/.vault_pass.txt
```

---

## 🔹 Ad-hoc Commands for Live Checks

### Ping all hosts:

```bash
ansible all -i inventory/hosts.ini -m ping
```

### Check disk usage:

```bash
ansible all -i inventory/hosts.ini -a "df -h | grep -E '/$|/mnt'"
```

### Check Docker status:

```bash
ansible all -i inventory/hosts.ini -a "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

---

## 🔹 Troubleshooting & Logs

### Run a single task from a role:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/grafana/deploy.yml \
  --start-at-task="Run Grafana container"
```

### Print variables for a host:

```bash
ansible -i inventory/hosts.ini home-node -m debug -a "var=hostvars['home-node']"
```

### Tail container logs remotely:

```bash
ansible home-node -i inventory/hosts.ini -a "docker logs -n 50 prometheus"
```

---

## 🔹 Notes & Tips

* Always run playbooks from the project root (`/project_root/ansible`).
* Never commit vault passwords — keep `.vault_pass.txt` local and gitignored.
* Use `--limit` to target a specific node or group (`home-node`, `edge-node`, `prod`, `qa`, etc.).
* For testing in sandbox environments, use `--limit qa` or `--limit vm`.
* Use dry runs (`--check`) before production changes.

---

