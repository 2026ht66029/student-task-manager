#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
find "$root/scripts" -name '*.sh' -print0 | xargs -0 -n1 bash -n
python3 -m py_compile "$root/app.py" "$root/tests/test_app.py"
test -f "$root/templates/index.html"
test -f "$root/static/style.css"
test -f "$root/sonar-project.properties"
test -f "$root/Jenkinsfile"
grep -q "pollSCM('H/2 \\* \\* \\* \\*')" "$root/Jenkinsfile"
grep -q "stage('Deploy')" "$root/Jenkinsfile"
grep -q 'sonar.qualitygate.wait=true' "$root/Jenkinsfile"
grep -q '"status":"UP"' "$root/scripts/deploy.sh"
printf '[PASS] Assignment 3 package structure, Python syntax, and shell syntax are valid.\n'

