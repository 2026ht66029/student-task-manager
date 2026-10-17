#!/usr/bin/env bash
set -Eeuo pipefail

failed=0

if systemctl is-active --quiet jenkins; then
  printf '[PASS] Jenkins service is active.\n'
else
  printf '[FAIL] Jenkins service is not active.\n' >&2
  failed=1
fi

if curl --silent --fail --max-time 5 http://127.0.0.1:8080/login >/dev/null; then
  printf '[PASS] Jenkins responds on port 8080.\n'
else
  printf '[FAIL] Jenkins does not respond on port 8080.\n' >&2
  failed=1
fi

sonar_status=$(curl --silent --fail --max-time 5 http://127.0.0.1:9000/api/system/status 2>/dev/null || true)
if grep -q '"status":"UP"' <<<"$sonar_status"; then
  printf '[PASS] SonarQube reports status UP.\n'
else
  printf '[FAIL] SonarQube is not ready: %s\n' "$sonar_status" >&2
  failed=1
fi

if [[ -x /opt/sonar-scanner/bin/sonar-scanner ]]; then
  printf '[PASS] SonarScanner CLI is installed.\n'
else
  printf '[FAIL] SonarScanner CLI is missing.\n' >&2
  failed=1
fi

exit "$failed"

