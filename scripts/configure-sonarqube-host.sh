#!/usr/bin/env bash
set -Eeuo pipefail

if (( EUID != 0 )); then
  printf 'Run this script with sudo.\n' >&2
  exit 1
fi

install -m 0644 /dev/stdin /etc/sysctl.d/99-sonarqube.conf <<'EOF'
vm.max_map_count=524288
fs.file-max=131072
EOF

install -m 0644 /dev/stdin /etc/security/limits.d/99-sonarqube.conf <<'EOF'
* soft nofile 131072
* hard nofile 131072
* soft nproc 8192
* hard nproc 8192
EOF

sysctl --system >/dev/null

printf 'vm.max_map_count=%s\n' "$(sysctl -n vm.max_map_count)"
printf 'fs.file-max=%s\n' "$(sysctl -n fs.file-max)"
printf 'SonarQube host limits are configured.\n'

