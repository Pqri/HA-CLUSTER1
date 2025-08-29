#!/usr/bin/env bash
set -euo pipefail
VIP_IP="${1:-192.168.56.30}"
NIC=$(ip route get "$VIP_IP" | sed -n 's/.*dev \([^ ]\+\).*/\1/p')
echo "$NIC"
