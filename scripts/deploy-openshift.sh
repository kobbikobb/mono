#!/usr/bin/env bash
# Deploys the API to a local MicroShift cluster managed by MINC
# (https://github.com/minc-org/minc). Requires a rootful Docker daemon.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
runtime="docker"
image="users-api:dev"
local_image="localhost/users-api"
release="mono"
namespace="mono"
context="microshift"
chart="$root/charts/mono-api"

for cmd in docker minc oc helm; do
  command -v "$cmd" >/dev/null || { echo "$cmd is not installed, see the README" >&2; exit 1; }
done

# Creates the cluster or restarts an existing one; either way MINC refreshes
# the kubeconfig. The overlay cache is mounted read-only and breaks CRI-O.
minc --provider "$runtime" create --disable-overlay-cache
kubectl config use-context "$context"
oc --context "$context" wait --for=condition=Ready node --all --timeout=180s

"$runtime" build -t "$image" "$root/api"

# The image only exists in the host's container storage, so copy it into
# MicroShift's CRI-O storage.
archive="$(mktemp)"
remote="/tmp/users-api.$$.tar"
cleanup() {
  "$runtime" exec microshift rm -f "$remote" >/dev/null 2>&1 || true
  rm -f "$archive"
}
trap cleanup EXIT
"$runtime" save "$image" -o "$archive"
"$runtime" cp "$archive" microshift:"$remote"
"$runtime" exec microshift \
  skopeo copy "docker-archive:$remote" "containers-storage:$local_image:dev"

helm upgrade --install "$release" "$chart" \
  --kube-context "$context" \
  --namespace "$namespace" --create-namespace \
  --set image.repository="$local_image" \
  --set image.tag=dev \
  --set route.enabled=true
# The tag is always :dev, so restart to pick up a rebuilt image.
oc --context "$context" -n "$namespace" rollout restart "deployment/$release"
oc --context "$context" -n "$namespace" rollout status "deployment/$release" --timeout=180s

host=""
for _ in $(seq 1 60); do
  host=$(oc --context "$context" -n "$namespace" get route "$release" \
    -o jsonpath='{.status.ingress[0].host}' 2>/dev/null || true)
  admitted=$(oc --context "$context" -n "$namespace" get route "$release" \
    -o jsonpath='{.status.ingress[0].conditions[?(@.type=="Admitted")].status}' 2>/dev/null || true)
  if [[ -n "$host" && "$admitted" == "True" ]]; then
    break
  fi
  host=""
  sleep 2
done

if [[ -z "$host" ]]; then
  oc --context "$context" -n "$namespace" describe route "$release" >&2 || true
  echo "The api Route was not admitted" >&2
  exit 1
fi

mapping=$("$runtime" port microshift 80/tcp 2>/dev/null | head -1 || true)
port="${mapping##*:}"
echo
echo "Route: http://$host:${port:-9080}/api/users"
