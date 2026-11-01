#!/usr/bin/env bash
# Deploys the API to a local MicroShift cluster managed by MINC
# (https://github.com/minc-org/minc). No root or Red Hat pull secret required.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
image="users-api:dev"
local_image="localhost/$image"
namespace="mono"
context="microshift"

command -v minc >/dev/null || { echo "minc is not installed, see the README" >&2; exit 1; }
command -v oc >/dev/null || { echo "oc is not installed" >&2; exit 1; }

runtime="${MINC_PROVIDER:-}"
if [[ -z "$runtime" ]]; then
  if command -v docker >/dev/null; then
    runtime=docker
  elif command -v podman >/dev/null; then
    runtime=podman
  else
    echo "Neither docker nor podman is available" >&2
    exit 1
  fi
fi

if ! "$runtime" inspect -f '{{.State.Running}}' microshift 2>/dev/null | grep -qx true; then
  # The overlay cache is mounted read-only and breaks CRI-O on some setups.
  minc --provider "$runtime" create --disable-overlay-cache
fi

echo "Waiting for the cluster..."
for _ in $(seq 1 60); do
  if oc --context "$context" get nodes 2>/dev/null | grep -q ' Ready '; then
    break
  fi
  sleep 2
done

"$runtime" build -t "$image" "$root/api"

# The image only exists in the host's container storage, so copy it into
# MicroShift's CRI-O storage.
archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
"$runtime" save "$image" -o "$archive"
"$runtime" cp "$archive" microshift:/tmp/users-api.tar
"$runtime" exec microshift \
  skopeo copy docker-archive:/tmp/users-api.tar "containers-storage:$local_image"
"$runtime" exec microshift rm -f /tmp/users-api.tar

oc --context "$context" apply -f "$root/openshift/manifests.yaml"
oc --context "$context" adm policy add-scc-to-user anyuid -z api -n "$namespace"
# The tag is always :dev, so restart to pick up a rebuilt image.
oc --context "$context" -n "$namespace" rollout restart deployment/api
oc --context "$context" -n "$namespace" rollout status deployment/api --timeout=180s

for _ in $(seq 1 30); do
  if oc --context "$context" -n "$namespace" get route api \
    -o jsonpath='{.status.ingress[0].host}' 2>/dev/null | grep -q .; then
    break
  fi
  sleep 2
done

host=$(oc --context "$context" -n "$namespace" get route api -o jsonpath='{.spec.host}')
mapping=$("$runtime" port microshift 80/tcp 2>/dev/null | head -1 || true)
port="${mapping##*:}"

if [[ -n "$port" ]]; then
  host="$host:$port"
fi

echo
echo "Route: http://$host/api/users"
