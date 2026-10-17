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

dnf -y install wget git maven python3 python3-pip fontconfig java-21-openjdk-devel
wget -q -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/rpm-stable/jenkins.repo
dnf -y install jenkins

systemctl daemon-reload
systemctl enable --now jenkins

printf '\nInstalled versions\n'
java -version
mvn -version
systemctl is-active jenkins

printf '\nJenkins is available on TCP port 8080. Use an SSH tunnel instead of exposing it publicly.\n'
printf 'Initial administrator password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword\n'

