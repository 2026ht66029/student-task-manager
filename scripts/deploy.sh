#!/usr/bin/env bash
set -Eeuo pipefail

build_id=${1:-manual}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_root=$(cd -- "$script_dir/.." && pwd)
deploy_root=${DEPLOY_ROOT:-/tmp/student-task-manager}
app_port=${APP_PORT:-5000}
release_dir="$deploy_root/releases/$build_id"
pid_file="$deploy_root/app.pid"
log_file="$deploy_root/app.log"

if [[ ! "$build_id" =~ ^[A-Za-z0-9._-]+$ ]]; then
  printf 'Invalid build identifier: %s\n' "$build_id" >&2
  exit 1
fi

mkdir -p "$release_dir" "$deploy_root/releases"
cp "$source_root/app.py" "$source_root/requirements.txt" "$release_dir/"
cp -R "$source_root/templates" "$source_root/static" "$release_dir/"

python3 -m venv "$release_dir/.venv"
"$release_dir/.venv/bin/python" -m pip install --upgrade pip
"$release_dir/.venv/bin/pip" install -r "$release_dir/requirements.txt"

if [[ -f "$pid_file" ]]; then
  old_pid=$(<"$pid_file")
  if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid"
    for _ in $(seq 1 20); do
      kill -0 "$old_pid" 2>/dev/null || break
      sleep 0.5
    done
  fi
  rm -f "$pid_file"
fi

ln -sfn "$release_dir" "$deploy_root/current"
: >"$log_file"
nohup "$release_dir/.venv/bin/gunicorn" \
  --chdir "$release_dir" \
  --bind "0.0.0.0:$app_port" \
  --workers 1 \
  --timeout 30 \
  --pid "$pid_file" \
  --access-logfile "$log_file" \
  --error-logfile "$log_file" \
  app:app >/dev/null 2>&1 &

for _ in $(seq 1 30); do
  if curl --silent --fail --max-time 2 "http://127.0.0.1:$app_port/health" |
    grep -q '"status":"UP"'; then
    printf 'Deployment %s is healthy at http://127.0.0.1:%s\n' "$build_id" "$app_port"
    exit 0
  fi
  sleep 1
done

printf 'Deployment failed its health check. Recent log output:\n' >&2
tail -50 "$log_file" >&2 || true
exit 1

