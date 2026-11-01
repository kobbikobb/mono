#!/usr/bin/env bash
# Curls the API through the kind Ingress or the OpenShift Route.
# Usage: ./scripts/curl-api.sh [path] [extra curl args...]   (default path: /api/users)
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$dir/lib.sh"

path="${1:-/api/users}"
shift || true

target="$(api_target)"

if [[ -z "$target" ]]; then
  echo "The API has no reachable address. Is the Ingress or Route ready?" >&2
  exit 1
fi

echo "curl http://$target$path" >&2
curl -sS -i -m 5 "$@" "http://$target$path"
echo
