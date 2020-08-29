#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

# Ensure the data folder is writable
[ -w "/data" ] || {
  >&2 printf "/data is not writable. Check your mount permissions.\n"
  exit 1
}

apt-cacher -f /config/apt-cacher.toml -logfile /dev/stdout -logformat "${APT_LOG_FORMAT:-plain}" -loglevel "${APT_LOG_LEVEL:-error}" &

case "${1:-}" in
  "hash-password")
    exec caddy "$@"
  ;;
  *)
    exec caddy run -config /config/caddy/main.conf --adapter caddyfile
  ;;
esac
