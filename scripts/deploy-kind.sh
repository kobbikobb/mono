#!/usr/bin/env bash
# Builds the images, loads them into kind, applies terraform (helm_release) and makes sure the
# cloud-provider-kind ingress controller is running.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$root/scripts/lib.sh"
api_image="ghcr.io/kobbikobb/mono/api:dev"
web_image="ghcr.io/kobbikobb/mono/web:dev"
context="kind-kind"

command -v kind >/dev/null || { echo "kind is not installed" >&2; exit 1; }
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

docker build -t "$api_image" "$root/api"
docker build -t "$web_image" "$root/web"

kubectl config use-context "$context"
kind load docker-image "$api_image" "$web_image" --name kind

terraform -chdir="$root/terraform" init -input=false
terraform -chdir="$root/terraform" apply -input=false -auto-approve -var image_tag=dev

# The tag is always :dev, so a rebuilt image only reaches the pod after a restart.
kubectl rollout restart deployment/mono-api deployment/mono-web
kubectl rollout status deployment/mono-api
kubectl rollout status deployment/mono-web

echo "Waiting for the ingress address..."
target=""
for _ in $(seq 1 30); do
  target="$(api_target)"
  [[ -n "$target" ]] && break
  sleep 2
done

if [[ -n "$target" ]]; then
  echo "Web: http://$target  API: http://$target/api/users"
else
  echo "The mono ingress has no reachable address. Is 'cloud-provider-kind' running?" >&2
fi
