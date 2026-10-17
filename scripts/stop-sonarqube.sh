#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
docker compose -f "$script_dir/../infrastructure/compose.sonarqube.yml" down
printf 'SonarQube stopped. Named volumes were preserved.\n'

