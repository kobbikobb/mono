#!/usr/bin/env bash
# Shared helpers for the local scripts.

# Prints a host-reachable "host:port" for the API, or nothing.
api_target() {
  local context
  context=$(kubectl config current-context 2>/dev/null || true)

  if [[ "$context" == *kind* ]]; then
    kind_target
  else
    route_target
  fi
}

# macOS/Windows run containers in a VM, so the ingress IP is not reachable and
# cloud-provider-kind publishes the gateway on a host port instead.
kind_target() {
  if command -v docker >/dev/null; then
    local gateway publish hostport
    gateway=$(docker ps --filter "name=kindccm-gw" --format '{{.Names}}' 2>/dev/null | head -1 || true)
    if [[ -n "$gateway" ]]; then
      publish=$(docker port "$gateway" 80/tcp 2>/dev/null | grep -E '^(0\.0\.0\.0|\[::\]):' | head -1 || true)
      hostport="${publish##*:}"
      if [[ -n "$hostport" ]]; then
        printf 'localhost:%s' "$hostport"
        return
      fi
    fi
  fi

  case "$(uname -s)" in
    Darwin | MINGW* | MSYS* | CYGWIN*) return ;;
  esac

  local addr
  addr=$(kubectl -n mono get ingress mono -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -z "$addr" ]]; then
    addr=$(kubectl -n mono get ingress mono -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  fi
  if [[ -n "$addr" ]]; then
    printf '%s' "$addr"
  fi
}

# OpenShift Route, using the MINC router port when the cluster runs in Docker.
route_target() {
  local host mapping port
  host=$(kubectl -n mono get route mono -o jsonpath='{.spec.host}' 2>/dev/null || true)
  [[ -n "$host" ]] || return 0

  mapping=$(docker port microshift 80/tcp 2>/dev/null | head -1 || true)
  port="${mapping##*:}"
  if [[ -n "$port" ]]; then
    printf '%s:%s' "$host" "$port"
  else
    printf '%s' "$host"
  fi
}
