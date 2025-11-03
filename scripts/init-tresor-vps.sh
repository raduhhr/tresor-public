#!/usr/bin/env bash
# init-tresor-vps.sh — Minimal bootstrap for remote VPS node
# Purpose: prepare a clean VPS for Ansible (create ansible user, set SSH key, enable sudo).
# No firewall, fail2ban, or Docker setup here — those are handled later via Ansible.

set -euxo pipefail

# ==========================
# 0️⃣ Install required packages
# ==========================
echo "[*] Installing Ansible dependencies..."
apt update -qq
apt install -y -qq python3 python3-apt sudo

# ==========================
# 1️⃣ Create the 'ansible' user
# ==========================
if id -u ansible >/dev/null 2>&1; then
  echo "[*] User 'ansible' already exists"
else
  echo "[*] Creating user 'ansible'"
  adduser --disabled-password --gecos "Ansible Automation" ansible
  usermod -aG sudo ansible
fi

# ==========================
# 2️⃣ SSH key setup for 'ansible'
# ==========================
echo "[*] Setting up SSH key for 'ansible'"
install -d -m 700 -o ansible -g ansible /home/ansible/.ssh

# Attempt to reuse any existing root key (injected by provider)
if [ -f /root/.ssh/authorized_keys ]; then
  echo "[*] Copying existing authorized key from root"
  install -m 600 -o ansible -g ansible /root/.ssh/authorized_keys /home/ansible/.ssh/authorized_keys
else
  echo "[!] No existing /root/.ssh/authorized_keys found."
  echo "Paste a public key for Ansible automation below:"
  read -r -p "Public key: " PUBKEY
  printf '%s\n' "$PUBKEY" >/home/ansible/.ssh/authorized_keys
  chown ansible:ansible /home/ansible/.ssh/authorized_keys
  chmod 600 /home/ansible/.ssh/authorized_keys
fi

# ==========================
# 3️⃣ Enable passwordless sudo
# ==========================
echo "[*] Enabling passwordless sudo for 'ansible'"
cat >/etc/sudoers.d/90-ansible-nopasswd <<'EOF'
ansible ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/90-ansible-nopasswd
visudo -q -c >/dev/null || echo "WARN: sudoers validation failed"

# ==========================
# 4️⃣ SSH hardening (minimal baseline)
# ==========================
echo "[*] Applying minimal SSH hardening"
# Disable password authentication
sed -i -E 's/^#?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
# Allow root only with key (disabled for password login)
sed -i -E 's/^#?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Restart SSH to apply changes
systemctl restart ssh || systemctl reload ssh || true

# ==========================
# ✅ Summary
# ==========================
echo
echo "=== VPS INIT COMPLETE ==="
echo "  User        : ansible (NOPASSWD sudo)"
echo "  SSH         : root login via key only, password auth disabled"
echo "  Next steps  : verify connection using your SSH key"
echo
echo "Example:"
echo "  ssh -i ~/.ssh/id_ed25519 ansible@<vps-ip>"
echo "  # Then run Ansible playbooks."
