#!/usr/bin/env bash
# Run on HOST to free port 8080 from any old containers or processes
set -euo pipefail
echo "Removing containers publishing 8080..."
ids=$(docker ps -a --format '{{.ID}} {{.Ports}}' | awk '/:8080->|0\.0\.0\.0:8080/ {print $1}')
[ -n "${ids:-}" ] && docker rm -f $ids || echo "No containers publishing 8080"
echo "Killing any process listening on 8080..."
fuser -k 8080/tcp || true
ss -lntp | grep ':8080 ' || echo "8080 is free"
