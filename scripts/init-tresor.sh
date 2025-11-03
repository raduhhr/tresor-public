#!/usr/bin/env bash
# init-tresor.sh — Minimal Ansible-ready bootstrap for Debian 12
# Purpose: prepare a fresh system for Ansible (SSH key auth, ansible user, sudo, python, rsync).
# Note: no firewall, fail2ban, or Docker setup — those are handled later by Ansible.

set -euo pipefail

# ==========================
# Config (override via env)
# ==========================
ANSIBLE_USER="${ANSIBLE_USER:-ansible}"
# Recommended: pass your pubkey dynamically at runtime:
#   ANSIBLE_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" SET_HOSTNAME="local-node" sudo -E ./init-tresor.sh
ANSIBLE_PUBKEY="${ANSIBLE_PUBKEY:-ssh-ed25519 AAAA...your_public_key_here... ansible@host}"

# Optional hostname
#   e.g., SET_HOSTNAME="local-node" or "vm-node"
SET_HOSTNAME="${SET_HOSTNAME:-}"

# Optional SSH restriction (space-separated users)
#   e.g., ALLOW_USERS="ansible mainuser"
ALLOW_USERS="${ALLOW_USERS:-}"

# ==========================
# Helpers
# ==========================
abort() { echo "ERROR: $*" >&2; exit 1; }
need_root() { [[ "${EUID}" -eq 0 ]] || abort "Run as root (sudo -i)."; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

# ==========================
# Pre-flight
# ==========================
need_root

# Ensure a valid SSH key
if [[ -z "${ANSIBLE_PUBKEY// }" || "${ANSIBLE_PUBKEY}" == ssh-ed25519\ AAAA...* ]]; then
  abort "ANSIBLE_PUBKEY is empty or still the placeholder. Pass it via env or edit the script."
fi

if ! grep -qi 'debian' /etc/os-release; then
  echo "WARN: This script was written for Debian-based systems. Proceeding anyway..."
fi

# ==========================
# Optional hostname
# ==========================
if [[ -n "${SET_HOSTNAME}" ]]; then
  current_hn="$(hostnamectl --static 2>/dev/null || hostname)"
  if [[ "${current_hn}" != "${SET_HOSTNAME}" ]]; then
    echo "[*] Setting hostname to '${SET_HOSTNAME}'"
    hostnamectl set-hostname "${SET_HOSTNAME}"
    if ! grep -qE "127\.0\.1\.1[[:space:]]+${SET_HOSTNAME}\b" /etc/hosts; then
      echo "127.0.1.1 ${SET_HOSTNAME}" >> /etc/hosts
    fi
  fi
fi

# ==========================
# System packages (minimal)
# ==========================
export DEBIAN_FRONTEND=noninteractive
echo "[*] Installing minimal dependencies (sudo, python3, python3-apt, rsync, openssh-server)"
apt-get update -qq
apt-get install -y -qq sudo python3 python3-apt rsync openssh-server

# ==========================
# Create Ansible user
# ==========================
if id -u "${ANSIBLE_USER}" >/dev/null 2>&1; then
  echo "[*] User '${ANSIBLE_USER}' already exists"
else
  echo "[*] Creating user '${ANSIBLE_USER}'"
  adduser --disabled-password --gecos "Ansible Automation" "${ANSIBLE_USER}"
fi

# ==========================
# SSH key auth setup
# ==========================
install -d -m 700 "/home/${ANSIBLE_USER}/.ssh"
AUTHZ="/home/${ANSIBLE_USER}/.ssh/authorized_keys"
touch "$AUTHZ"
chmod 600 "$AUTHZ"
if ! grep -Fq "${ANSIBLE_PUBKEY}" "$AUTHZ"; then
  printf '%s\n' "${ANSIBLE_PUBKEY}" >> "$AUTHZ"
fi
chown -R "${ANSIBLE_USER}:${ANSIBLE_USER}" "/home/${ANSIBLE_USER}/.ssh"

# ==========================
# Passwordless sudo
# ==========================
echo "[*] Enabling passwordless sudo for '${ANSIBLE_USER}'"
cat >/etc/sudoers.d/99-ansible <<EOF
${ANSIBLE_USER} ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/99-ansible
visudo -q -c >/dev/null || abort "sudoers validation failed"

# ==========================
# SSH daemon minimal hardening
# ==========================
echo "[*] Writing minimal SSH config drop-in"
install -d /etc/ssh/sshd_config.d
DROPIN="/etc/ssh/sshd_config.d/99-bootstrap.conf"
cat >"$DROPIN" <<'EOF'
# Minimal SSH config — further hardening handled by Ansible later
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Optionally restrict who can SSH in
if [[ -n "${ALLOW_USERS// }" ]]; then
  echo "AllowUsers ${ALLOW_USERS}" >> "$DROPIN"
fi

# Validate and reload SSH
if cmd_exists sshd; then
  sshd -t
fi
systemctl reload ssh || systemctl restart ssh || true

# ==========================
# Summary
# ==========================
ip_show="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo
echo "=== INIT COMPLETE ==="
echo "  Hostname     : $(hostname)"
echo "  Primary IP   : ${ip_show:-<unknown>}"
echo "  Ansible user : ${ANSIBLE_USER} (NOPASSWD sudo)"
echo "  SSH          : root login DISABLED, password auth DISABLED"
if [[ -n "${ALLOW_USERS// }" ]]; then
  echo "  SSH Restrict : AllowUsers ${ALLOW_USERS}"
fi
echo
echo "Next steps (from your workstation):"
echo "  ssh -i ~/.ssh/id_ed25519 <ANSIBLE_USER>@${ip_show:-<host-ip>}"
echo "  # then run your Ansible playbooks"
