# Cheatsheet

# Cheatsheet (Tresor)

Handy commands and references for daily use with this project.

* * *

## Common Flags

```bash
--limit prod|qa # run on subset of hosts
-v / -vv / -vvv # verbosity levels
--check # dry-run mode
--diff # show file diffs
--tags x --skip-tags y # run or skip specific tags


⸻

Inventory and Sanity Checks

# Ping all hosts
ansible -i inventory/hosts.ini all -m ping

# Ping only prod / qa
ansible -i inventory/hosts.ini prod -m ping
ansible -i inventory/hosts.ini qa -m ping


⸻

Verbosity and Limits

# Normal run
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --limit prod

# Very verbose (debug SSH, module args, etc.)
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --limit qa -vvv


⸻

Syntax Check, Task Listing, Dry-Run

# Lint-like safety check
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --syntax-check

# See tasks that would run
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --list-tasks

# Dry-run (check mode, no changes)
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --limit prod --check


⸻

Playbooks by Stage

# Base system (hardening, SSH, updates)
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-base.yml --limit prod
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-base.yml --limit prod

# Docker engine (rootful + userns-remap)
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-docker.yml --limit prod
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-docker.yml --limit prod

# Networks (bridge setup)
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --limit qa
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-networks.yml --limit qa
ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --limit prod
ansible-playbook -i inventory/hosts.ini playbooks/infra/verify-networks.yml --limit prod


⸻

Useful One-Liners

# Gather a few facts (OS, hostname)
ansible -i inventory/hosts.ini prod -m setup -a 'filter=ansible_*distribution*'
ansible -i inventory/hosts.ini qa -m setup -a 'filter=ansible_hostname'

# Confirm Docker reachable on target
ansible -i inventory/hosts.ini prod -m community.docker.docker_host_info


⸻

Pretty Output

# YAML-style output for readability
ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory/hosts.ini playbooks/infra/setup-networks.yml --limit prod


⸻

Ansible Galaxy Cheatsheet

Installed Collections

ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

Requirements File

# collections/requirements.yml
collections:
 - Name: <REDACTED>
 - Name: <REDACTED>
 - Name: <REDACTED>

Install them in bulk:

ansible-galaxy collection install -r collections/requirements.yml

Role Scaffolding

# Create a new role skeleton
ansible-galaxy role init roles/<new_role_name>

```