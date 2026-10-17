#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
compose_file="$script_dir/../infrastructure/compose.sonarqube.yml"

docker compose -f "$compose_file" up --detach

printf 'Waiting for SonarQube to become ready'
for _ in $(seq 1 90); do
  status=$(curl --silent --max-time 2 http://127.0.0.1:9000/api/system/status 2>/dev/null || true)
  if grep -q '"status":"UP"' <<<"$status"; then
    printf '\nSonarQube is ready at http://127.0.0.1:9000\n'
    exit 0
  fi
  printf '.'
  sleep 5
done

printf '\nSonarQube did not become ready within 450 seconds.\n' >&2
docker compose -f "$compose_file" logs --tail=100 sonarqube >&2
exit 1

