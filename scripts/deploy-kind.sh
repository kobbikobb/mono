#!/usr/bin/env bash
# Builds the API image, loads it into kind, and installs the Helm chart.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$root/scripts/lib.sh"
image="users-api:dev"
release="mono"
namespace="mono"
context="kind-kind"
chart="$root/charts/mono-api"

for cmd in docker kind kubectl helm; do
  command -v "$cmd" >/dev/null || { echo "$cmd is not installed, see the README" >&2; exit 1; }
done

kind get clusters | grep -qx kind || { echo "No kind cluster named 'kind'. Run: kind create cluster --name kind" >&2; exit 1; }

ensure_ingress_controller() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    if ! pgrep -qf cloud-provider-kind; then
      if command -v cloud-provider-kind >/dev/null; then
        echo "Start the ingress controller in another terminal: sudo cloud-provider-kind" >&2
      else
        echo "Install cloud-provider-kind (brew install cloud-provider-kind) and run: sudo cloud-provider-kind" >&2
      fi
    fi
    return
  fi

  if docker inspect -f '{{.State.Running}}' cloud-provider-kind 2>/dev/null | grep -qx true; then
    echo "cloud-provider-kind container is already running."
    return
  fi

  docker rm -f cloud-provider-kind >/dev/null 2>&1 || true
  latest="$(curl -sL -o /dev/null -w '%{url_effective}' https://github.com/kubernetes-sigs/cloud-provider-kind/releases/latest || true)"
  version="$(basename "${latest:-v0.12.0}")"
  version="${version:-v0.12.0}"
  echo "Starting cloud-provider-kind ${version}..."
  docker run -d --name cloud-provider-kind --rm \
    --network host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    "registry.k8s.io/cloud-provider-kind/cloud-controller-manager:${version}" >/dev/null
}

ensure_ingress_controller

docker build -t "$image" "$root/api"

kubectl config use-context "$context"
kind load docker-image "$image" --name kind

helm upgrade --install "$release" "$chart" \
  --namespace "$namespace" --create-namespace \
  --set image.repository=users-api \
  --set image.tag=dev \
  --set ingress.enabled=true

# The tag is always :dev, so restart to pick up a rebuilt image.
kubectl -n "$namespace" rollout restart "deployment/$release"
kubectl -n "$namespace" rollout status "deployment/$release" --timeout=180s

echo "Waiting for the ingress address..."
target=""
for _ in $(seq 1 30); do
  target="$(api_target)"
  [[ -n "$target" ]] && break
  sleep 2
done

if [[ -n "$target" ]]; then
  echo "API: http://$target/api/users"
else
  echo "The api ingress has no reachable address. Is 'cloud-provider-kind' running?" >&2
  exit 1
fi
