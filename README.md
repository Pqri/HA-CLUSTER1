# HA Cluster in Docker (Pacemaker + Corosync) — Config-Only on Host

Corosync & Pacemaker run **fully inside the `ha-stack` container**. Host keeps only config files.
Test service is a simple **Flask frontend** managed via OCF `docker` agent. Image includes DRBD tools for later.

## IP & Hostnames (example)
- serverA = `192.168.56.27`
- serverB = `192.168.56.28`
- VIP     = `192.168.56.30/24`

> Update `docker-compose.yml` `extra_hosts` and `corosync/corosync.conf` accordingly.
> On **serverB**, change `hostname: serverB` in compose.

---

## 0) Layout
```
ha-github/
├─ docker/               # Dockerfile for control-plane image
├─ supervisor/           # (optional) supervisor overrides
├─ corosync/             # REQUIRED: corosync.conf + authkey
├─ flask-frontend/       # test app (no DB)
├─ scripts/              # helper scripts
└─ docker-compose.yml
```

## 1) Build the control-plane image (serverA)
```bash
cd docker
docker build -t fiqri/ha-stack:2.2-ha .
# load to serverB
docker save fiqri/ha-stack:2.2-ha | ssh pqri@serverB 'docker load'
```

## 2) Generate the corosync authkey (serverA)
```bash
./scripts/generate_authkey.sh    # writes corosync/authkey (mode 400)
scp corosync/authkey pqri@serverB:~/ha/corosync/authkey
```

## 3) Start containers on both nodes
On **each host**:
```bash
docker compose up -d
```
> On serverB, edit `docker-compose.yml` and set `hostname: serverB` first.

## 4) Bootstrap the cluster (run *inside* serverA container)
```bash
docker exec -it ha-stack bash
# inside container:
./cluster/scripts/pcs_bootstrap_cluster.sh || true
# or run commands manually:
# pcs host auth serverA serverB -u hacluster -p 123
# pcs cluster setup --name ha-cluster serverA serverB
# pcs cluster start --all
# pcs cluster enable --all
# pcs property set stonith-enabled=false
# pcs property set no-quorum-policy=stop
# pcs status
```

## 5) Build the Flask frontend image
```bash
cd ../flask-frontend
docker build -t flask-frontend:latest .
docker save flask-frontend:latest | ssh pqri@serverB 'docker load'
```

## 6) Create resources (run *inside* serverA container)
```bash
docker exec -it ha-stack bash
./cluster/scripts/pcs_create_resources.sh
# This auto-detects NIC for the VIP based on route to VIP_IP (default 192.168.56.30)
```

## 7) Test
```bash
curl -sS http://192.168.56.30:8080/ | head -n 5
```

## 8) Failover demo
```bash
docker exec -it ha-stack bash -lc './cluster/scripts/failover_demo.sh'
```

---

## Troubleshooting

- **`crm_mon` / `cibadmin` missing** → ensure the image includes `pacemaker-cli-utils` (this repo's Dockerfile does).
- **Corosync FATAL / CS_ERR_LIBRARY** → check `corosync.conf` syntax (multiline node blocks), hostname matches `nodelist`, and `authkey` mode is `400`.
- **VIP not created** → set correct `nic=`; the script auto-detects via `ip route get $VIP_IP`.
- **HTTP 500 / Address already in use (8080)** → free port 8080 on the active host:
  ```bash
  ./scripts/cleanup_port_8080.sh     # on the active HOST
  # then inside container:
  pcs resource cleanup flask_frontend; pcs resource restart flask_frontend
  ```
- **See which node is active**:
  ```bash
  docker exec -it ha-stack bash -lc 'pcs status | sed -n "/Full List of Resources/,$p"'
  ```

## Notes
- Supervisor overrides in `supervisor/` are **optional**; remove those two mounts to use image defaults.
- Pacemaker state stays under `/var/lib/pacemaker` **inside container** (default & stable).
- Logs go to `/home/cluster/log/*` inside the container.
