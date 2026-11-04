#!/usr/bin/env bash
# Shared helpers for the local scripts.

# Prints "https" when the mono Route terminates TLS, otherwise "http".
api_scheme() {
  local kube tls
  kube=$(command -v kubectl || command -v oc || true)
  if [[ -n "$kube" ]]; then
    tls=$("$kube" -n mono get route mono -o jsonpath='{.spec.tls.termination}' 2>/dev/null || true)
  fi
  if [[ -n "${tls:-}" ]]; then printf https; else printf http; fi
}

# Prints a host-reachable "host:port" for the mono Ingress or Route, or nothing.
# macOS/Windows run containers in a VM, so the ingress IP is not reachable and
# cloud-provider-kind publishes the gateway on a host port instead.
api_target() {
  local kube
  kube=$(command -v kubectl || command -v oc || true)

  # The Route lookup uses the current context, so it comes before the kind
  # gateway, which is found even when another cluster is selected.
  if [[ -n "$kube" ]]; then
    local host port
    host=$("$kube" -n mono get route mono \
      -o jsonpath='{.status.ingress[0].host}' 2>/dev/null || true)
    if [[ -n "$host" ]]; then
      if [[ "$("$kube" config current-context 2>/dev/null)" == microshift ]] &&
        command -v docker >/dev/null; then
        local mapping containerport=80
        [[ "$(api_scheme)" == https ]] && containerport=443
        mapping=$(docker port microshift "$containerport/tcp" 2>/dev/null | head -1 || true)
        port="${mapping##*:}"
      fi
      printf '%s%s' "$host" "${port:+:$port}"
      return
    fi
  fi

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

  if [[ -n "$kube" ]]; then
    local addr
    addr=$("$kube" get ingress mono -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [[ -z "$addr" ]]; then
      addr=$("$kube" get ingress mono -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    fi
    if [[ -n "$addr" ]]; then
      printf '%s' "$addr"
    fi
  fi
}
