#!/usr/bin/env bash
# Curls the mono ingress using a host-reachable address.
# Usage: ./scripts/curl-api.sh [path] [extra curl args...]   (default path: /api/users)
# A TLS Route on local MicroShift has a self-signed certificate: pass -k to accept it.
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$dir/lib.sh"

path="${1:-/api/users}"
shift || true

target="$(api_target)"

if [[ -z "$target" ]]; then
  echo "The mono Ingress/Route has no address. Is 'cloud-provider-kind' running?" >&2
  exit 1
fi

scheme="$(api_scheme)"
echo "curl $scheme://$target$path" >&2
curl -sS -i -m 5 "$@" "$scheme://$target$path"
echo
