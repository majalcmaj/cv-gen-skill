#!/usr/bin/env bash
set -euo pipefail

status=0

check_bash() {
  if ((BASH_VERSINFO[0] >= 4)); then
    echo "[ok] bash ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} >= 4"
  else
    echo "[missing] bash >= 4 (found ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}) — upgrade bash"
    status=1
  fi
}

check_docker_cli() {
  if command -v docker >/dev/null 2>&1; then
    echo "[ok] docker CLI on PATH"
  else
    echo "[missing] docker CLI — install Docker: https://docs.docker.com/get-docker/"
    status=1
  fi
}

check_docker_daemon() {
  if docker info >/dev/null 2>&1; then
    echo "[ok] docker daemon reachable"
  else
    echo "[missing] docker daemon unreachable — start Docker (e.g. \`systemctl start docker\` or open Docker Desktop)"
    status=1
  fi
}

check_bash
check_docker_cli
check_docker_daemon

exit "$status"
