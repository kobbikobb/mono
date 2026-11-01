#!/usr/bin/env bash
# Builds the API image, loads it into kind, applies terraform and runs the ingress controller.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
image="users-api:dev"
context="kind-kind"

command -v kind >/dev/null || { echo "kind is not installed" >&2; exit 1; }
kind get clusters | grep -qx kind || { echo "No kind cluster named 'kind'. Run: kind create cluster" >&2; exit 1; }
command -v cloud-provider-kind >/dev/null || { echo "cloud-provider-kind is not installed. Run: brew install cloud-provider-kind" >&2; exit 1; }

! pgrep -qf cloud-provider-kind || { echo "cloud-provider-kind is already running. Stop it first: sudo pkill -f cloud-provider-kind" >&2; exit 1; }

docker build -t "$image" "$root/api"

kubectl config use-context "$context"
kind load docker-image "$image"

terraform -chdir="$root/terraform" init -input=false
set +e
terraform -chdir="$root/terraform" plan -input=false -detailed-exitcode
plan_status=$?
set -e

case "$plan_status" in
  0) echo "No terraform changes." ;;
  2) terraform -chdir="$root/terraform" apply -input=false -auto-approve ;;
  *) exit "$plan_status" ;;
esac

# The tag is always :dev, so a rebuilt image only reaches the pod after a restart.
kubectl rollout restart deployment/api
kubectl rollout status deployment/api

sudo "$(command -v cloud-provider-kind)"
