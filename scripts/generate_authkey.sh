#!/usr/bin/env bash
set -euo pipefail
# Generate corosync authkey into ./corosync/authkey (mode 400)
here="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
img="${1:-fiqri/ha-stack:2.2-ha}"
docker run --rm --entrypoint bash -v "$here/corosync:/cor" "$img" -lc 'corosync-keygen -l && cp /etc/corosync/authkey /cor/authkey'
chmod 400 "$here/corosync/authkey"
echo "authkey generated at $here/corosync/authkey (mode 400)"
