#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

# Ensure the data folder is writable
[ -w "/data" ] || {
  >&2 printf "/data is not writable. Check your mount permissions.\n"
  exit 1
}

case "${1:-}" in
  "hash-password")
    exec caddy "$@"
  ;;
  *)
    # Start the cacher itself
    apt-cacher -f /config/apt-cacher.toml -logfile /dev/stdout -logformat "${APT_LOG_FORMAT:-plain}" -loglevel "${APT_LOG_LEVEL:-error}" &
    # Bonjour the container
    if [ "${MDNS_NAME:-}" ]; then
      goello-server -name "$MDNS_NAME" -host "$MDNS_HOST" -port "$PORT" -type "$MDNS_TYPE" &
    fi
    # Start the caddy proxy wrapper
    # XXX assuming DNS verification instrumenting gandi, we could get foo.public.com point to $UNIQUE_HOST, which will internally (only) resolve to this here
    # while still allowing for LE TLS
    exec caddy run -config /config/caddy/main.conf --adapter caddyfile
  ;;
esac
