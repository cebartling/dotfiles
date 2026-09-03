#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"

echo "==> Installing prerequisites"
apt-get update
apt-get install -y ca-certificates curl

echo "==> Adding Docker's official GPG key"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "==> Adding Docker apt repository (resolute)"
cat > /etc/apt/sources.list.d/docker.sources <<'SRC'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: resolute
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
SRC

echo "==> Installing Docker Engine, CLI, containerd, buildx and compose"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Enabling and starting services"
systemctl enable --now docker.service containerd.service

echo "==> Adding '$TARGET_USER' to the docker group"
usermod -aG docker "$TARGET_USER"

echo
echo "==> Verifying"
docker version
docker run --rm hello-world

echo
echo "Done. Log out and back in (or run: newgrp docker) so '$TARGET_USER' can use docker without sudo."
