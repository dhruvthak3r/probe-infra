#!/bin/bash
set -euxo pipefail

SWAPFILE="/swapfile"
SWAPSIZE_MB="1024"

if ! sudo swapon --show | grep -q "^${SWAPFILE}"; then
  if [ ! -f "${SWAPFILE}" ]; then
    sudo fallocate -l "${SWAPSIZE_MB}M" "${SWAPFILE}" || sudo dd if=/dev/zero of="${SWAPFILE}" bs=1M count="${SWAPSIZE_MB}"
    sudo chmod 600 "${SWAPFILE}"
    sudo mkswap "${SWAPFILE}"
  fi

  sudo swapon "${SWAPFILE}"
fi

if ! grep -q "^${SWAPFILE}[[:space:]]" /etc/fstab; then
  echo "${SWAPFILE} none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
fi


if command -v dnf >/dev/null 2>&1; then
  sudo dnf update -y
  sudo dnf install -y docker
elif command -v yum >/dev/null 2>&1; then
  sudo yum update -y
  sudo yum install -y docker
else
  echo "No supported package manager found (dnf/yum)." >&2
  exit 1
fi

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker ec2-user

if ! sudo docker compose version >/dev/null 2>&1; then
  COMPOSE_VERSION="v2.27.0"
  ARCH="$(uname -m)"
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -fL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

echo "Docker version:"
sudo docker --version
echo "Docker Compose version:"
sudo docker compose version

echo "Starting containers..."
cd /home/ec2-user
sudo docker compose up -d
