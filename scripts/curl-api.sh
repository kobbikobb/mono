#!/usr/bin/env bash
# Reads the address cloud-provider-kind assigned to the api ingress and curls it.
# Usage: ./scripts/curl-api.sh [path] [extra curl args...]   (default path: /api/users)
set -euo pipefail

path="${1:-/api/users}"
shift || true

addr=""
if command -v kubectl >/dev/null; then
  addr=$(kubectl get ingress api -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -z "$addr" ]]; then
    addr=$(kubectl get ingress api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  fi
fi

if [[ -z "$addr" ]]; then
  echo "The api ingress has no address. Is 'cloud-provider-kind' running?" >&2
  exit 1
fi

echo "curl http://$addr$path" >&2
curl -sS -i -m 5 "$@" "http://$addr$path"
echo
