#!/usr/bin/env bash
# Run inside the ha-stack container on serverA
set -euo pipefail
VIP_IP="${VIP_IP:-192.168.56.30}"
VIP_CIDR="${VIP_CIDR:-24}"
NIC="${NIC:-$(ip route get "$VIP_IP" | sed -n 's/.*dev \([^ ]\+\).*/\1/p')}"
echo "Using NIC=$NIC VIP=$VIP_IP/$VIP_CIDR"

pcs resource create vip ocf:heartbeat:IPaddr2 \
  ip="$VIP_IP" cidr_netmask="$VIP_CIDR" nic="$NIC" \      op monitor interval=10s timeout=20s 2>/dev/null || pcs resource update vip ip="$VIP_IP" cidr_netmask="$VIP_CIDR" nic="$NIC"

pcs resource create flask_frontend ocf:heartbeat:docker \      name=flask-frontend-ha image=flask-frontend:latest \      run_opts="--network=host --name=flask-frontend-ha --restart=unless-stopped" \      reuse=true force_kill=true \      op start timeout=90s op stop timeout=90s op monitor interval=20s timeout=60s 2>/dev/null || true

pcs resource group delete app_group 2>/dev/null || true
pcs resource group add app_group vip flask_frontend

pcs resource defaults update resource-stickiness=200
pcs resource cleanup vip flask_frontend
pcs status
