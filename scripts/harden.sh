#!/usr/bin/env bash
# Durcissement de base du serveur Ubuntu.
# Usage : sudo bash scripts/harden.sh
set -euo pipefail

echo "== 1/4 Pare-feu ufw =="
apt-get update -y
apt-get install -y ufw
ufw allow OpenSSH              # 22 (avant enable, pour ne pas se couper l'accès)
ufw allow 80,443,3000,9090/tcp
ufw default deny incoming
ufw default allow outgoing
ufw --force enable
ufw status verbose

echo "== 2/4 Durcissement SSH (clé uniquement, root désactivé) =="
cat > /etc/ssh/sshd_config.d/99-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
MaxAuthTries 3
EOF
sshd -t && systemctl restart ssh
echo "SSH durci."

echo "== 3/4 fail2ban (anti-bruteforce SSH) =="
apt-get install -y fail2ban
cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled  = true
maxretry = 4
bantime  = 1h
findtime = 10m
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban
fail2ban-client status sshd || true

echo "== 4/4 Mises à jour de sécurité automatiques =="
apt-get install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades || true

echo "== Durcissement terminé =="
