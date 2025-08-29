#!/usr/bin/env bash
# Run inside ha-stack container on serverA
set -euo pipefail
echo "Before:"
pcs resource status
echo "Standby serverA (move to serverB)"
pcs node standby serverA
sleep 6
pcs resource status
echo "Unstandby serverA"
pcs node unstandby serverA
sleep 3
pcs resource status
