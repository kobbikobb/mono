#!/usr/bin/env bash
# Builds and runs the api and web containers with docker compose.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

docker compose -f "$root/docker-compose.yml" up --build "$@"
