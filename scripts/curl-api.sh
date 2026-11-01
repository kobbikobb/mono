#!/usr/bin/env bash
# Curls the api ingress, using the host port published by cloud-provider-kind when
# available (macOS/Windows) or the address assigned to the ingress (Linux).
# Usage: ./scripts/curl-api.sh [path] [extra curl args...]   (default path: /api/users)
set -euo pipefail

path="${1:-/api/users}"
shift || true

target=""

# macOS and Windows run containers in a VM, so the ingress address is not
# reachable from the host. cloud-provider-kind publishes the gateway on a host
# port instead.
if command -v docker >/dev/null; then
  gateway=$(docker ps --filter "name=kindccm-gw" --format '{{.Names}}' 2>/dev/null | head -1 || true)
  if [[ -n "$gateway" ]]; then
    publish=$(docker port "$gateway" 80/tcp 2>/dev/null | grep -E '^(0\.0\.0\.0|\[::\]):' | head -1 || true)
    hostport="${publish##*:}"
    if [[ -n "$hostport" ]]; then
      target="localhost:$hostport"
    fi
  fi
fi

# On Linux the gateway address is directly reachable.
if [[ -z "$target" ]] && command -v kubectl >/dev/null; then
  addr=$(kubectl get ingress api -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -z "$addr" ]]; then
    addr=$(kubectl get ingress api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  fi
  if [[ -n "$addr" ]]; then
    target="$addr"
  fi
fi

if [[ -z "$target" ]]; then
  echo "The api ingress has no address. Is 'cloud-provider-kind' running?" >&2
  exit 1
fi

echo "curl http://$target$path" >&2
curl -sS -i -m 5 "$@" "http://$target$path"
echo
