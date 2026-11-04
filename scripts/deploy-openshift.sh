#!/usr/bin/env bash
# Builds both images, loads them into a local MicroShift cluster managed by MINC
# (https://github.com/minc-org/minc) and installs the chart with a Route.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
runtime="docker"
api_image="ghcr.io/kobbikobb/mono/api:dev"
web_image="ghcr.io/kobbikobb/mono/web:dev"
release="mono"
namespace="mono"
context="microshift"

for cmd in docker minc oc helm curl; do
  command -v "$cmd" >/dev/null || { echo "$cmd is not installed, see the README" >&2; exit 1; }
done

# The overlay cache is mounted read-only and breaks CRI-O, so create the cluster without it.
# An existing container keeps the mounts it was created with, so recreate it.
if "$runtime" container inspect microshift >/dev/null 2>&1; then
  minc --provider "$runtime" delete
fi
minc --provider "$runtime" create --disable-overlay-cache
oc config use-context "$context"
oc --context "$context" wait --for=condition=Ready node --all --timeout=180s

"$runtime" build -t "$api_image" "$root/api"
"$runtime" build -t "$web_image" "$root/web"

# The images only exist in the host's container storage, so copy them into
# MicroShift's CRI-O storage under the same references the chart uses.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

load_image() {
  local image="$1" name archive remote
  name="${image//[\/:]/_}"
  archive="$tmp/$name.tar"
  remote="/tmp/$name.$$.tar"
  "$runtime" save "$image" -o "$archive"
  "$runtime" cp "$archive" microshift:"$remote"
  "$runtime" exec microshift \
    skopeo copy "docker-archive:$remote" "containers-storage:$image"
  "$runtime" exec microshift rm -f "$remote"
}

load_image "$api_image"
load_image "$web_image"

helm upgrade --install "$release" "$root/charts/mono" \
  --kube-context "$context" \
  --namespace "$namespace" --create-namespace \
  --set api.image.tag=dev \
  --set web.image.tag=dev \
  --set ingress.enabled=false \
  --set route.enabled=true

# The tag is always :dev, so restart to pick up rebuilt images.
oc --context "$context" -n "$namespace" rollout restart \
  "deployment/$release-api" "deployment/$release-web"
oc --context "$context" -n "$namespace" rollout status \
  "deployment/$release-api" --timeout=180s
oc --context "$context" -n "$namespace" rollout status \
  "deployment/$release-web" --timeout=180s

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
  echo "The Route was not admitted" >&2
  exit 1
fi

mapping=$("$runtime" port microshift 80/tcp 2>/dev/null | head -1 || true)
port="${mapping##*:}"
url="http://$host:${port:-9080}/api/users"

# The Route reports Admitted before the router has endpoints; wait for traffic.
for _ in $(seq 1 30); do
  curl -fsS --max-time 5 "$url" >/dev/null 2>&1 && break
  sleep 2
done
if ! curl -fsS --max-time 5 "$url" >/dev/null; then
  echo "The Route is admitted but $url is not serving" >&2
  exit 1
fi

echo
echo "Web: http://$host:${port:-9080}/"
echo "API: $url"
