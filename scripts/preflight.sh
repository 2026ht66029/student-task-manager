#!/usr/bin/env bash
set -Eeuo pipefail

green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
reset='\033[0m'

pass() { printf "${green}[PASS]${reset} %s\n" "$*"; }
warn() { printf "${yellow}[WARN]${reset} %s\n" "$*"; }
fail() { printf "${red}[FAIL]${reset} %s\n" "$*"; }

printf 'DevOps M4 lab preflight\n'
printf '========================\n'

if [[ ! -r /etc/os-release ]]; then
  fail '/etc/os-release is unavailable.'
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
printf 'Operating system: %s\n' "${PRETTY_NAME:-unknown}"

if [[ "${ID:-}" == 'rocky' && "${VERSION_ID:-}" == 9.* ]]; then
  pass 'Rocky Linux major version 9 detected.'
else
  fail 'This package is designed for Rocky Linux 9.x.'
  exit 1
fi

arch=$(uname -m)
if [[ "$arch" == 'x86_64' || "$arch" == 'aarch64' ]]; then
  pass "Supported 64-bit architecture detected: $arch"
else
  fail "Unsupported architecture: $arch"
  exit 1
fi

cpu_count=$(getconf _NPROCESSORS_ONLN)
if (( cpu_count >= 2 )); then
  pass "CPU cores: $cpu_count"
else
  warn "Only $cpu_count CPU core detected; SonarQube recommends at least 2."
fi

memory_kib=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
memory_gib=$((memory_kib / 1024 / 1024))
if (( memory_kib >= 4194304 )); then
  pass "Memory: approximately ${memory_gib} GiB"
else
  warn "Memory is approximately ${memory_gib} GiB; SonarQube recommends at least 4 GiB."
fi

disk_kib=$(df -Pk / | awk 'NR==2 {print $4}')
disk_gib=$((disk_kib / 1024 / 1024))
if (( disk_kib >= 10485760 )); then
  pass "Free space on root filesystem: approximately ${disk_gib} GiB"
else
  warn "Only approximately ${disk_gib} GiB is free; increase disk capacity if possible."
fi

for port in 5000 8080 9000; do
  if ss -ltn "sport = :$port" 2>/dev/null | tail -n +2 | grep -q .; then
    warn "TCP port $port is already in use."
  else
    pass "TCP port $port is available."
  fi
done

map_count=$(sysctl -n vm.max_map_count 2>/dev/null || printf '0')
file_max=$(sysctl -n fs.file-max 2>/dev/null || printf '0')

if (( map_count >= 524288 )); then
  pass "vm.max_map_count=$map_count"
else
  warn "vm.max_map_count=$map_count; run configure-sonarqube-host.sh."
fi

if (( file_max >= 131072 )); then
  pass "fs.file-max=$file_max"
else
  warn "fs.file-max=$file_max; run configure-sonarqube-host.sh."
fi

printf '\nExisting tools\n'
for command_name in java mvn git docker curl; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '  %-8s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    printf '  %-8s not installed yet\n' "$command_name"
  fi
done

printf '\nPreflight complete. Review every warning before continuing.\n'

