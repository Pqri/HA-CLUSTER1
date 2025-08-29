#!/usr/bin/env bash
# Run inside the ha-stack container on serverA AFTER both nodes up with compose
set -euo pipefail
PCS_PASS="${PCS_PASS:-123}"
pcs host auth serverA serverB -u hacluster -p "$PCS_PASS"
pcs cluster setup --name ha-cluster serverA serverB
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=stop
pcs status
