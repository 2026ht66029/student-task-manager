#!/usr/bin/env bash
set -Eeuo pipefail

if (( EUID != 0 )); then
  printf 'Run this script with sudo.\n' >&2
  exit 1
fi

version='8.0.1.6346'
case "$(uname -m)" in
  x86_64) scanner_arch='x64' ;;
  aarch64 | arm64) scanner_arch='aarch64' ;;
  *)
    printf 'Unsupported architecture: %s\n' "$(uname -m)" >&2
    exit 1
    ;;
esac

archive="sonar-scanner-cli-${version}-linux-${scanner_arch}.zip"
download_url="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${archive}"
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

dnf -y install curl unzip
curl --fail --location --show-error --output "$work_dir/$archive" "$download_url"
unzip -q "$work_dir/$archive" -d "$work_dir"

if [[ -e /opt/sonar-scanner ]]; then
  backup="/opt/sonar-scanner.backup.$(date +%Y%m%d%H%M%S)"
  mv /opt/sonar-scanner "$backup"
  printf 'Previous scanner moved to %s\n' "$backup"
fi

mv "$work_dir/sonar-scanner-${version}-linux-${scanner_arch}" /opt/sonar-scanner
chown -R root:root /opt/sonar-scanner
chmod -R a+rX /opt/sonar-scanner

/opt/sonar-scanner/bin/sonar-scanner --version
printf 'SonarScanner CLI installed at /opt/sonar-scanner.\n'

