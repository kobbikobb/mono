#!/usr/bin/env bash
# Shared helpers for the local scripts.

# Prints a host-reachable "host:port" for the mono Ingress or Route, or nothing.
# macOS/Windows run containers in a VM, so the ingress IP is not reachable and
# cloud-provider-kind publishes the gateway on a host port instead.
api_target() {
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

  if command -v kubectl >/dev/null; then
    local host port
    host=$(kubectl -n mono get route mono \
      -o jsonpath='{.status.ingress[0].host}' 2>/dev/null || true)
    if [[ -n "$host" ]]; then
      if [[ "$(kubectl config current-context 2>/dev/null)" == microshift ]] &&
        command -v docker >/dev/null; then
        local mapping
        mapping=$(docker port microshift 80/tcp 2>/dev/null | head -1 || true)
        port="${mapping##*:}"
      fi
      printf '%s%s' "$host" "${port:+:$port}"
      return
    fi
  fi

  case "$(uname -s)" in
    Darwin | MINGW* | MSYS* | CYGWIN*) return ;;
  esac

  if command -v kubectl >/dev/null; then
    local addr
    addr=$(kubectl get ingress mono -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [[ -z "$addr" ]]; then
      addr=$(kubectl get ingress mono -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    fi
    if [[ -n "$addr" ]]; then
      printf '%s' "$addr"
    fi
  fi
}
