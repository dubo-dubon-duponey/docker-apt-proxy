#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

# Ensure the data folder is writable
[ -w "/data" ] || {
  >&2 printf "/data is not writable. Check your mount permissions.\n"
  exit 1
}

mkdir -p /data/go-apt-mirror

LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_FORMAT="${LOG_FORMAT:-plain}"

# Run once configured
args=(apt-mirror -f /config/apt-mirror.toml -logfile /dev/stdout -logformat "$LOG_FORMAT" -loglevel "$LOG_LEVEL")

exec "${args[@]}" "$@"
