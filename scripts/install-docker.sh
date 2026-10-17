#!/usr/bin/env bash
set -Eeuo pipefail

if (( EUID != 0 )); then
  printf 'Run this script with sudo.\n' >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  printf '/etc/os-release is unavailable.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != 'rocky' || "${VERSION_ID:-}" != 9.* ]]; then
  printf 'This installer supports Rocky Linux 9.x only.\n' >&2
  exit 1
fi

dnf -y install dnf-plugins-core

if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
  dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
fi

dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

if id jenkins >/dev/null 2>&1; then
  usermod -aG docker jenkins
  systemctl restart jenkins
fi

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != 'root' ]]; then
  usermod -aG docker "$SUDO_USER"
fi

docker version
docker compose version
systemctl is-active docker

printf '\nDocker is ready. Log out and back in once before using Docker without sudo.\n'

