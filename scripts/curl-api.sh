#!/usr/bin/env bash
# Finds the host port cloud-provider-kind mapped to the ingress gateway and curls the API.
# Usage: ./scripts/curl-api.sh [path] [extra curl args...]   (default path: /api/users)
set -euo pipefail

path="${1:-/api/users}"
shift || true

port=$(docker ps --filter "name=kindccm-gw" --format '{{.Ports}}' \
  | grep -o '0\.0\.0\.0:[0-9]*->80/tcp' | head -1 | sed -E 's/0\.0\.0\.0:([0-9]+)->.*/\1/')

if [[ -z "$port" ]]; then
  echo "No gateway container found. Is 'sudo cloud-provider-kind' running?" >&2
  exit 1
fi

echo "curl localhost:$port$path" >&2
curl -sS -i -m 5 "$@" "localhost:$port$path"
echo
